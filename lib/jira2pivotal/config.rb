module Jira2Pivotal
  class Config < Base

    def initialize(path, project_name)
      if File.exist?(path)
        @config = YAML.load_file(path)
        project_options = @config.delete(project_name)
        @config.merge!(project_options) unless project_options.nil?

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
