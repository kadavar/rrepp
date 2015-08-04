class NotificationService
  attr_accessor :monitoring_hash

  def initialize(monitoring_hash)
    @monitoring_hash = monitoring_hash
  end

  def check_and_notificate
    monitoring_hash.each do |project, status|
      send_emails(project, status[:emails]) unless process_exists?(status[:pid])
    end
  end

  private

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
end
