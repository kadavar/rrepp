require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class Bridge < Thor
  desc 'sync', 'sync stories and issues'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def sync
    bridge = init_bridge
    bridge.sync!
  end

  no_commands do
    def init_bridge
      puts "You supplied the file: " + "#{options[:config]}".yellow
      puts "Project is : " + "#{options[:project]}".yellow

      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)

      bridge = ::Jira2Pivotal::Bridge.new(config_file_path, options[:project])
      bridge
    end
  end
end
