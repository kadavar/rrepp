require File.expand_path('../boot', __FILE__)
require 'rails/all'

Bundler.require(:default, Rails.env)

require 'net/http'
require 'jira'
require 'open-uri'
require 'yaml'
require 'colorize'
require 'highline/import'

module J2p
  class Application < Rails::Application
    config.watchable_dirs['lib'] = [:rb]
    config.autoload_paths << Rails.root.join('lib')
    config.autoload_paths += %W(#{config.root}/app/models/project)
    config.assets.enabled = true
  end
end
