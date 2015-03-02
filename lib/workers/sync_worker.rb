require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class SyncWorker
  include Sidekiq::Worker

  sidekiq_options failures: true, retry: false

  def perform(config, project)
    bridge = ::Jira2Pivotal::Bridge.new(config, project)
    bridge.sync!
  end
end