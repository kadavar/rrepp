Airbrake.configure do |config|
  config.api_key = 'a5d7d328bed91fe089df0ff2112c64f6'
  config.host    = 'errbit.hnd.sm.ua'
  config.port    = 80
  config.secure  = config.port == 443
  config.development_environments = []
  config.ignore_only  = []
end
