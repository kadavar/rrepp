require 'thor/rails'

class Notification < Thor
  include Thor::Rails

  desc 'notification', 'notification about crashed processes'
  def notificate
    puts 'started notification service'

    Process.daemon()

    scheduler = Rufus::Scheduler.new

    scheduler.every updated_config['notification_repeat_time'], first_in: updated_config['notification_first_start'] do
      NotificationWorker.perform_async({ 'project' => options[:project] }, random_hash)
    end

    scheduler.join
  end
end
