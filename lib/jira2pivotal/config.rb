module Jira2Pivotal
  class Config < Base

    def initialize(config)
      @config = set_logger(config)
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

    private

    def set_logger(config)
      config.merge!(logger: init_logger(config))
    end

    def init_logger(config)
      Jira2Pivotal::Logger.new(config)
    end
  end
end
