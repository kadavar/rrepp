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

    updated_config = ThorHelpers::Config.new(project: options[:project], config: options[:config]).update_config

    ThorHelpers::Redis.new.insert_config(updated_config, random_hash)

    Daemons.daemonize()

    update_project_information

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['script_repeat_time'], first_in: updated_config['script_first_start'] do
      SyncWorker.perform_async(random_hash)
    end

    scheduler.join
  end
end
