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

gem 'bootstrap-sass', '~> 3.3.5'
gem 'twitter-bootstrap-rails'
gem 'font-awesome-rails'
gem 'sass-rails'
gem 'less-rails'
gem 'therubyracer'
gem 'uglifier'

gem 'coffee-rails'
gem 'haml-rails'

gem 'jquery-rails'
gem 'jquery-ui-rails'

# Pivotal Tracker Api
gem 'tracker_api', github: 'dashofcode/tracker_api', branch: 'master'

# Jira Api
gem 'jira-ruby'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'overcommit'
  gem 'rubocop', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'pry'
  gem 'pry-byebug'
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
  gem 'capistrano-slack', '1.3.1'
end

group :production do
  gem 'unicorn'
end

group :test do
  # browser level testing
  gem 'poltergeist'

  gem 'capybara'
  gem 'launchy'
  gem 'factory_girl_rails'

  # fake redis implemented in ruby
  gem 'mock_redis'

  # to test sorting, timing
  gem 'timecop'

  gem 'shoulda-matchers'
  gem 'fuubar'
  gem 'database_cleaner'
end
