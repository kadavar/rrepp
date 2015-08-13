ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'spec_helper'

require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

RSpec.configure &:infer_spec_type_from_file_location!
