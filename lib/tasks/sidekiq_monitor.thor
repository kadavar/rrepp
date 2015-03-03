# require 'sidekiq/web'

# class SideKiqMonitor < Thor
#   desc 'start', 'start sidekiq web app'
#   method_option :bind, aliases: '-b', desc: 'Bind to start', default: '0.0.0.0'
#   method_option :port, aliases: '-p', desc: 'Free port', default: 9696
#   def start
#     # optional: Process.daemon (and take care of Process.pid to kill process later on)
#     Process.daemon
#     app = Sidekiq::Web
#     app.set :environment, :production
#     app.set :bind, options[:bind]
#     app.set :port, options[:port]
#     app.run!
#   end
# end
