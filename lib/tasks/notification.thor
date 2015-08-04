require 'thor/rails'

class Notification < Thor
  include Thor::Rails

  desc 'notificate', 'notification about crashed processes'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: '/config.yml'

  def notificate
    puts 'started notification service'

    Process.daemon()

    scheduler = Rufus::Scheduler.new

    config = load_config

    scheduler.every config['notification_repeat_time'], first_in: config['notification_first_start'] do
      NotificationWorker.perform_async
    end

    scheduler.join
  end

  no_commands do
    def load_config
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      config_file_exists?(config_file_path)

      YAML.load_file(config_file_path)
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
