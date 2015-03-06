require 'thor/rails'

class Bridge < Thor
  include Thor::Rails

  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'project_configs/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    puts "You supplied the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = update_config.merge('log_file_name' => create_log_file, 'project_name' => options[:project])

    Daemons.daemonize()

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['script_repeat_time'], first_in: updated_config['script_first_start'] do
      SyncWorker.perform_async(updated_config)
    end

    scheduler.join
  end

  no_commands do
    def create_log_file
      file_name = "#{options[:project].gsub(' ', '_')}.log"
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
