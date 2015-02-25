require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class Bridge < Thor
  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'project_configs/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    puts "You supplied the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = update_config

    say 'Set repeat time: 1s 5m 10h'
    repeat_time = ask 'time: '


    Daemons.daemonize()

    scheduler = Rufus::Scheduler.new

    scheduler.every repeat_time, first_in: 5 do
      SyncWorker.perform_async(updated_config, options[:project])
    end

    scheduler.join
  end

  no_commands do
    def update_config
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      config_file_exists?(config_file_path)

      receive_passwords(YAML.load_file(config_file_path))
    end

    def receive_passwords(config)
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
