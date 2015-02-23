module Jira2Pivotal
  class Config < Base

    def initialize(path, project_name)
      if File.exist?(path)
        @config = YAML.load_file(path)
        project_options = @config.delete(project_name)
        @config.merge!(project_options) unless project_options.nil?

        say("Jira user: #{@config['jira_login']}")
        @config['jira_password'] = ask('Jira password: ') { |q| q.echo = 'x' }

        say("Pivotal Requester: #{@config['tracker_requester']}") { |q| q.echo = 'x'}
        @config['tracker_token'] = ask('Pivotal tracker api: ')

        @config
      else
        puts "Missing config file: #{path}"
        exit 1
      end
    end

    def [](key)
      @config[key]
    end

    def jira_url
      "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"
    end

    def merge!(attrs)
      @config.merge!(attrs)
    end
  end
end
