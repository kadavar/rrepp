module Jira2Pivotal
  class Config < Base

    def initialize(config, project_name)
      @config = config
      project_options = @config.delete(project_name)
      @config.merge!(project_options) unless project_options.nil?
      @config.merge!('project_name' => project_name)

      logger = init_logger(@config['log_file_name'])
      logger.formatter = logger_formatter

      @config.merge!(logger: logger)

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

    private

    def init_logger(log_file_name)
      Logger.new("tmp/logs/#{log_file_name}")
    end

    def logger_formatter
      proc do |severity, datetime, progname, msg|
        if severity == "INFO" || severity == "WARN"
          if @config['sync_action'] == 'INVOICED'
            "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%6N')} ##{Process.pid} P##{@config['project_name']}] #{@config['sync_action']} -- #{msg}\n"
          else
            "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%6N')} ##{Process.pid} P##{@config['project_name']}]   #{@config['sync_action']} -- #{msg}\n"
          end
        else
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%6N')} ##{Process.pid} P##{@config['project_name']}] #{severity} -- #{msg}\n"
        end
      end
    end
  end
end
