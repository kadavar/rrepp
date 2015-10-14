set :rails_env,   'production'
set :branch,      'master'
set :deploy_to,   -> { "/home/#{user}/apps/#{domain_name}" }

top.env.current_environment.set 'RAILS_ENV', 'production'

namespace :script do
  task :create_folders do
    run "if [ -d /home/arnold/apps/j2p/tmp ]; then mkdir -p /home/arnold/apps/j2p/tmp/logs && mkdir -p /home/arnold/apps/j2p/tmp/pids; else mkdir -p /home/arnold/apps/j2p/tmp && mkdir -p /home/arnold/apps/j2p/tmp/logs, && mkdir -p /home/arnold/apps/j2p/tmp/pids}; fi"
  end

  task :run_bundle do
    run 'cd /home/arnold/apps/j2p; bundle install'
  end
end

# namespace :deploy do
#   task :restart do
#     run "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else cd #{deploy_to}/current && bundle exec unicorn_rails -c #{unicorn_config} -E #{rails_env} -D; fi"
#   end
# end
