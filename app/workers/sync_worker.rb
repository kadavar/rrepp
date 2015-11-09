class SyncWorker
  include Sidekiq::Worker

  sidekiq_options failures: true, retry: false, backtrace: true, queue: "jtp_#{Rails.env}"

  def perform(project, hash_to_redis)
    bridge = JiraToPivotal::Bridge.new(hash_to_redis)
    bridge.sync!
  end
end
