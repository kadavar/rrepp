class ThorHelpers::Config < ThorHelpers::Base
  def initialize(options={})
    @project_name = options[:project]
    @config_name  = options[:config]
  end

  def update_config
    find_and_update_config
  end

  private

  def create_log_file
    file_name = "#{@project_name.underscore.gsub(' ', '_')}.log"
    file = open("log/#{file_name}", File::WRONLY | File::APPEND | File::CREAT)

    file_name
  end

  def find_and_update_config
    config_file_path = File.expand_path("../../../#{@config_name}", __FILE__)
    config_file_exists?(config_file_path)

    config = YAML.load_file(config_file_path)
    config.merge!('log_file_name' => create_log_file, 'project_name' => @project_name)

    ask_credentials(config)
  end

  def ask_credentials(config)
    say("Jira User: #{config['jira_login']}")
    config['jira_password'] = ask("Jira Password:  ") { |q| q.echo = false }

    say("\nPivotal Requester: #{config['tracker_requester']}")
    config['tracker_token'] = ask('Pivotaltracker API token: ') { |q| q.echo = false }

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
