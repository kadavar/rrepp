require 'thor/rails'

class Bridge < Thor
  include Thor::Rails

  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'project_configs/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    random_hash = SecureRandom.hex(30)

    puts "You provided the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = update_config.merge('log_file_name' => create_log_file, 'project_name' => options[:project])

    Process.daemon()

    updated_config['process_pid'] = Process.pid
    set_params_to_redis(updated_config, random_hash)

    push_monitoring_to_redis(options[:project], options[:emails], Process.pid)

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['script_repeat_time'], first_in: updated_config['script_first_start'] do
      SyncWorker.perform_async({ 'project' => options[:project] }, random_hash)
    end

    scheduler.join
  end

  no_commands do
    def create_log_file
      file_name = "#{options[:project].underscore.gsub(' ', '_')}.log"
      file = open("log/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)

      file_name
    end

    def update_config
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      config_file_exists?(config_file_path)

      ask_credentials(YAML.load_file(config_file_path))
    end

    def ask_credentials(config)
      say("Jira User: #{config['jira_login']}")
      config['jira_password'] = ask("Jira Password:  ", echo: false)

      say("\nPivotal Requester: #{config['tracker_requester']}")
      config['tracker_token'] = ask('Pivotaltracker API token: ', echo: false)

      return config
    end

    def encrypt_params(params, random_hash)
      crypt = ActiveSupport::MessageEncryptor.new(random_hash)
      crypt.encrypt_and_sign(params.to_json)
    end

    def set_params_to_redis(params, random_hash)
      Sidekiq.redis { |connection| connection.set(random_hash, encrypt_params(params, random_hash)) }
    end

    def update_monitoring(project)
      monitoring_hash = get_monitoring

      status = monitoring_hash[project]
      status[:previous_start] = status[:current_start]
      status[:current_start] = Time.now

      monitoring_hash[project] = status

      set_params_to_redis(monitoring_hash, :monitoring)
    end

    def get_monitoring
      Sidekiq.redis { |connection| connection.get(:monitoring) }
    end

    def push_monitoring_to_redis(project, emails, pid)
      monitoring_hash = {}
      monitoring_hash.merge(get_monitoring)

      status = { start: Time.now, pid: pid, emails: emails }
      monitoring_hash[project] = status

      set_params_to_redis(monitoring_hash, :monitoring)
    end

    def config_file_exists?(path)
      true if File.open(path)

    rescue Errno::ENOENT => e
      Airbrake.notify_or_ignore(
        e,
        parameters: { config_path: path },
        cgi_data: ENV.to_hash,
        )

      puts "Missing config file: #{path}"
      exit 1
    end
  end
end
