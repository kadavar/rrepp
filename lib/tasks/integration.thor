require 'thor/rails'
require 'pry'

class Integration < Thor
  include Thor::Rails

  desc 'update', 'update integration for pivotal'
  method_option :config, aliases: '-c', desc: 'Configuration file', default: 'project_configs/config.yml'
  method_option :project, aliases: '-p', desc: 'Project name from config file', required: true
  def update
    puts "You provided the file: " + "#{options[:config]}".yellow
    puts "Project is : " + "#{options[:project]}".yellow

    updated_config = update_config

    client = TrackerApi::Client.new(token: updated_config['tracker_token'])

    integrations = client.get("/projects/#{updated_config['tracker_project_id']}/integrations").body
    mapped_integrations = integrations.map {|i| { i['base_url'] => i['id'] } }.reduce Hash.new, :merge
    base_url = "#{updated_config['jira_uri_scheme']}://#{updated_config['jira_host']}"

    project = client.project(updated_config['tracker_project_id'])
    filter = 'story_type:bug,chore,feature state:unstarted,started,finished,delivered,rejected'

    puts "\n Start update integration".blue
    project.stories(filter: filter).each do |story|
      story.integration_id = mapped_integrations[base_url]
      story.save
      putc '.'
    end
  end


  no_commands do
    def update_config
      config_file_path = File.expand_path("../../../#{options[:config]}", __FILE__)
      config_file_exists?(config_file_path)

      ask_credentials(YAML.load_file(config_file_path))
    end

    def ask_credentials(config)
      say("\nPivotal Requester: #{config['tracker_requester']}")
      config['tracker_token'] = ask('Pivotaltracker API token: ', echo: false)

      return config
    end

    def config_file_exists?(path)
      true if File.open(path)

    rescue Errno::ENOENT => e
      Airbrake.notify_or_ignore(
        e,
        parameters: { config_path: path },
        cgi_data: ENV.to_hash,
        )

      puts "Missing config file: #{path}"
      exit 1
    end
  end
end
