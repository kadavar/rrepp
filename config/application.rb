require File.expand_path('../boot', __FILE__)
# require 'rails/all'
require "active_model/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
require "rails/test_unit/railtie"

Bundler.require(:default, Rails.env)

module J2p
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.watchable_dirs['lib'] = [:rb]
    # config.autoload_paths << Rails.root.join('lib')
    config.assets.enabled = true
  end
end
