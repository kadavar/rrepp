require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class SyncWorker
  include Sidekiq::Worker

  sidekiq_options failures: true, retry: false

  def perform(config)
    bridge = ::JiraToPivotal::Bridge.new(config)
    bridge.sync!
  end
end
