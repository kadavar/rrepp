class SyncWorker
  include Sidekiq::Worker

  sidekiq_options failures: true, retry: false

  def perform(config)
    bridge = ::JiraToPivotal::Bridge.new(config)
    bridge.sync!
  end
end
