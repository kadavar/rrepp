require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class Bridge < Thor
  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'project_configs/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    puts "You supplied the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = update_config.merge('log_file_name' => create_log_file)

    Daemons.daemonize()

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['script_repeat_time'], first_in: updated_config['script_first_start'] do
      SyncWorker.perform_async(updated_config, options[:project])
    end

    scheduler.join
  end

  no_commands do
    def create_log_file
      file_name = "#{options[:project].gsub(' ', '_')}.log"
      file = open("logs/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)
      file_name
      return file_name
    end

    def update_config
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      config_file_exists?(config_file_path)

      ask_credentials(YAML.load_file(config_file_path))
    end

    def ask_credentials(config)
      say("Jira User: #{config['jira_login']}")
      config['jira_password'] = ask('Jira Password: ') { |q| q.echo = 'x' }

      say("Pivotal Requester: #{config['tracker_requester']}") { |q| q.echo = 'x'}
      config['tracker_token'] = ask('Pivotaltracker API token: ')

      return config
    end

    def config_file_exists?(path)
      if File.exist?(path)
        true
      else
        puts "Missing config file: #{path}"
        exit 1
      end
    end

  end
end
