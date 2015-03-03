module Jira2Pivotal
  class ScriptLogger
    def initialize(config)
      @config = config

      logger.formatter = formatter
      logger
    end

    def logger
      @logger ||= Logger.new("tmp/logs/#{@config['log_file_name']}")
    end

    def jira_logger
      @jira_logger ||= Jira2Pivotal::Loggs::JiraLogger.new(logger, @config)
    end

    def write_daemon_pin_in_log
      logger.debug File.open("#{Dir.pwd}/daemons.rb.pid") if File.exists?("#{Dir.pwd}/daemons.rb.pid")
    end

    def error_log(exception)
      logger.error e.response.body
      logger.error e.backtrace.inspect
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
