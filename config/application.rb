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

require 'net/http'
require 'jira'
require 'pivotal-tracker'
require 'open-uri'
require 'yaml'
require 'colorize'
require 'rufus-scheduler'
require 'highline/import'
require 'daemons'
require 'pry'
require 'pry-byebug'


module J2p
  class Application < Rails::Application
    config.watchable_dirs['lib'] = [:rb]
    config.autoload_paths << Rails.root.join('lib')
    config.assets.enabled = true
  end
end
