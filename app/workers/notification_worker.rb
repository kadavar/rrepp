class NotificationWorker
  include Sidekiq::Worker

  def perform
    monitoring_hash = Sidekiq.redis { |connection| connection.get('monitoring') }

    NotificationService.check_and_notify(JSON.parse monitoring_hash)
  end
end
