require 'thor/rails'

class Integration < Thor
  include Thor::Rails

  desc 'update', 'update integration for pivotal'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'config/integrations/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def update
    puts "You provided the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = read_config_add_credentials

    client = TrackerApi::Client.new(token: updated_config['tracker_token'])

    integrations = client.get("/projects/#{updated_config['tracker_project_id']}/integrations").body
    mapped_integrations = integrations.map {|i| { i['base_url'] => i['id'] } }.reduce Hash.new, :merge
    base_url = "#{updated_config['jira_uri_scheme']}://#{updated_config['jira_host']}"

    project = client.project(updated_config['tracker_project_id'])
    # TODO
    # verify if there any possibility to handle filters in other way
    # if this is impossible, create Filter class to handle those filter strings
    filter = 'story_type:bug,chore,feature state:unstarted,started,finished,delivered,rejected'

    puts "\n Start update integration".blue
    project.stories(filter: filter).each do |story|
      story.integration_id = mapped_integrations[base_url]
      story.save
      putc '.'
    end
  end

  no_commands do
    def read_config_add_credentials
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      raise "Cannot read config file #{config_file_path}" unless File.readable?(config_file_path)

      config = YAML.load_file(config_file_path)

      say("\nPivotal Requester: #{config['tracker_requester']}")
      config['tracker_token'] = ask('Pivotaltracker API token: ', echo: false)

      config
    end
  end
end
