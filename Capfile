require 'recap/recipes/ruby'
require 'recap/recipes/rails'
require 'recap/tasks/bundler'
require 'sushi/ssh'
require 'capistrano_colors'
require 'capistrano-unicorn'
require 'capistrano/sidekiq'
require 'capistrano/slack'
require './config/deploy/recap'

set :default_environment, { 'PATH' => '~/.rbenv/shims:~/.rbenv/bin:$PATH' }

set(:sidekiq_cmd) { "#{fetch(:bundle_cmd, "bundle")} exec sidekiq -C config/sidekiq.yml" }
set(:sidekiq_pid) { File.join(deploy_to, 'tmp', 'pids', 'sidekiq.pid') }
set(:sidekiq_log) { File.join(deploy_to, 'log', 'sidekiq.log') }

server '83.143.200.3:55022', :web, :app, :db, primary: true

set :domain_name,      'j2p'
set :ruby_version,     '2.2.0'
set :application,      'j2p'
set :repository,       'ssh://git@gl.jetruby.com:10022/jetruby/j2p.git'
set :user,             'arnold'
set :application_user, 'arnold'

ssh_options[:forward_agent] = true

#== Multistage
set :stages, %w(production staging)
set :default_stage, 'production'
require 'capistrano/ext/multistage'

#== Recipes
# set :recipes_dir, File.expand_path('/cap-recipes', __FILE__)
# load recipes_dir + '/config/recipes/base'
# load recipes_dir + '/config/recipes/nginx'
# load recipes_dir + '/config/recipes/rbenv'

#== Fallback vars for old recipes
set(:current_path) { deploy_to }
set(:shared_path)  { deploy_to }

set(:rails_server)  { 'unicorn' }
set :unicorn_user,    -> { nil}
set :unicorn_pid,     -> { "#{shared_path}/tmp/pids/unicorn.pid"  }
set :unicorn_config,  -> { "#{shared_path}/config/unicorn.rb" }
set :unicorn_log,     -> { "#{shared_path}/log/unicorn.log"   }
set :unicorn_workers, 1

after 'deploy:restart', 'unicorn:reload'    # app IS NOT preloaded
#after 'deploy:restart', 'unicorn:restart'   # app preloaded
# after 'deploy:restart', 'unicorn:duplicate' # before_fork hook implemented (zero downtime deployments)

before 'sidekiq:quiet', 'script:run_bundle'
before 'sidekiq:start', 'script:create_folders'

# Slack
set :slack_token, 'SRxImWhjpPYBcID29xE8cjR5' # comes from inbound webhook integration
set :slack_room, '#j2p'
set :slack_subdomain, 'jetruby'

set :slack_application, 'Jira2Pivotal'
set :slack_username, 'CapBot'
set :slack_emoji, ':rocket:'
