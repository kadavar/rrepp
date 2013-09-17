require File.expand_path('../../../lib/jira2pivotal.rb', __FILE__)

class Bridge < Thor
  desc 'bridge:sync FILE', 'an example task'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'config.yml'
  method_option :project, aliases: '-p', desc: 'Project name', required: true
  def sync
    puts "You supplied the file: #{options[:config]}"
    puts "Project is : #{options[:project]}"

    config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)

    bridge = ::Jira2Pivotal::Bridge.new(config_file_path, options[:project])
    bridge.sync!
  end
end
