Sidekiq.configure_server do |config|
  config.redis = { namespace: "jtp_#{Rails.env}" }
end

Sidekiq.configure_client do |config|
  config.redis = { namespace: "jtp_#{Rails.env}" }
end
