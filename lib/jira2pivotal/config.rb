module Jira2Pivotal
  class Config < Base

    def initialize(config, project_name)
      @config = config
      project_options = @config.delete(project_name)
      @config.merge!(project_options) unless project_options.nil?

      @config
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
