source 'https://rubygems.org'

gem 'rails', '4.2'
gem 'certified'
gem 'thor'
gem 'thor-rails'
gem 'colorize'
gem 'highline'
gem 'rufus-scheduler'
gem 'airbrake'
gem 'figaro'
gem 'simple_form'
gem "responders"

gem 'pg'

gem 'highlight', require: 'simplabs/highlight'
gem 'kaminari'

# Background jobber
gem 'sidekiq'
gem 'sidekiq-failures'
gem 'sidekiq-limit_fetch'

gem 'sinatra', require: false
gem 'differ', github: 'emintham/differ'

gem 'newrelic_rpm'

gem 'twitter-bootstrap-rails'
gem 'sass-rails'
gem 'less-rails'
gem 'therubyracer'
gem 'uglifier'

gem 'coffee-rails'
gem 'haml-rails'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# Pivotal Tracker Api
gem 'tracker_api', github: 'dashofcode/tracker_api'

# Jira Api
gem 'jira-ruby'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry'
  gem 'pry-byebug'

  # code linters
  gem 'overcommit'
  gem 'rubocop', require: false

  # more useful exception page, auto open a console at the exception site
  gem 'better_errors'
end

group :development, :test do
  gem 'rspec-rails'
end

group :tools do
  gem 'capistrano', '~> 2.0'
  gem 'capistrano_colors'
  gem 'sushi'
  gem 'recap', '~> 1.2'
  gem 'capistrano-unicorn', require: false
  gem 'capistrano-sidekiq'
  gem 'bundler-audit'
  gem 'capistrano-colorized-stream'
  gem 'capistrano-slack'
end

group :production do
  gem 'unicorn'
end

group :test do
  # browser level testing
  gem 'capybara'
  gem 'poltergeist' # headless js driver for capybara

  gem 'factory_girl'

  # fake redis implemented in ruby
  gem 'mock_redis'

  # the one true way of mocking and stubbing
  gem 'mocha', require: false

  # to test sorting, timing
  gem 'timecop'

  gem 'shoulda-matchers'
  gem 'fuubar'
end
