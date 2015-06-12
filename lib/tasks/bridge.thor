require 'thor/rails'

class Bridge < Thor
  include Thor::Rails

  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'config/integrations/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    random_hash = SecureRandom.hex(30)

    puts "You provided the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = ThorHelpers::Config.new(project: options[:project], config: options[:config]).update_config

    Process.daemon()

    updated_config['process_pid'] = Process.pid
    set_params_to_redis(updated_config, random_hash)

    ThorHelpers::Redis.insert_config(updated_config, random_hash)
    ThorHelpers::Redis.update_project(options[:project])

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['script_repeat_time'], first_in: updated_config['script_first_start'] do
      SyncWorker.perform_async({ 'project' => options[:project] }, random_hash)
    end

    scheduler.join
  end
end
