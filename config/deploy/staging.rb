set :rails_env,   'staging'
set :branch,      'staging'
set :deploy_to,   -> { "/home/#{user}/apps/#{stage}.#{domain_name}" }

top.env.current_environment.set 'RAILS_ENV', 'staging'

namespace :script do
  task :create_folders do
    run "if [ -d /home/arnold/apps/j2p/tmp ]; then mkdir -p /home/arnold/apps/j2p/tmp/logs && mkdir -p /home/arnold/apps/j2p/tmp/pids; else mkdir -p /home/arnold/apps/j2p/tmp && mkdir -p /home/arnold/apps/j2p/tmp/logs, && mkdir -p /home/arnold/apps/j2p/tmp/pids}; fi"
  end

  task :run_bundle do
    run "cd /home/arnold/apps/j2p; bundle install"
  end
end
