require 'sidekiq/web'

class SideKiqMonitor < Thor
  desc 'start', 'start sidekiq web app'
  def start
    # optional: Process.daemon (and take care of Process.pid to kill process later on)
    Process.daemon
    app = Sidekiq::Web
    app.set :environment, :production
    app.set :bind, '0.0.0.0'
    app.set :port, 9494
    app.run!
  end
end
