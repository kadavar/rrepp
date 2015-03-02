module Jira2Pivotal
  class Logger
    def initialize(config)
      @config = config

      logger.formatter = formatter
      logger
    end

    def logger
      @logger ||= Logger.new("tmp/logs/#{@config['log_file_name']}")
    end

    def jira_logger
      @jira_logger ||= Jira2Pivotal::Logger::JiraLogger.new(logger, @config)
    end

    private

    def formatter
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
