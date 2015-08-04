class NotificationWorker
  include Sidekiq::Worker

  def perform
    monitoring_hash = Sidekiq.redis { |connection| connection.get('monitoring') }

    notification_service = NotificationService.new(JSON.parse monitoring_hash)
    notification_service.check_and_notificate
  end
end
