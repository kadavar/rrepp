class NotificationService
  class << self
    def check_and_notify(monitoring_hash)
      projects_to_remove = []

      monitoring_hash.each do |project, status|
        next if process_exists?(status['pid'])
        projects_to_remove << project

        send_emails(project, status['emails'])
      end

      remove_from_monitoring(projects_to_remove, monitoring_hash)
    end

    def process_exists?(pid)
      Process.kill(0, pid.to_i)
      true
    rescue Errno::ESRCH # No such process
      false
    rescue Errno::EPERM # The process exists, but you dont have permission to send the signal to it.
      true
    end

    def send_emails(project, emails)
      emails.each do |email|
        NotificationMailer.delay.notification_email(project, email)
      end
    end

    def remove_from_monitoring(projects_to_remove, monitoring_hash)
      projects_to_remove.each { |project| monitoring_hash.delete(project) }

      Sidekiq.redis { |connection| connection.set('monitoring', monitoring_hash.to_json) }
    end
  end
end
