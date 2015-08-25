# TODO: refactor this code while doing
# https://github.com/hndsm/j2p/issues/58
module JiraToPivotal
  class ScriptLogger
    include Singleton

    attr_accessor :config

    def init_logger
      logger.formatter = formatter
      logger
    end

    def update_config(params)
      config.merge!(params)
    end

    def logger
      @logger ||= Logger.new("log/#{config['log_file_name']}")
    end

    def jira_logger
      @jira_logger ||= JiraToPivotal::Loggs::JiraLogger.new(logger, config)
    end

    def attrs_log(attrs, type = 'Before save')
      logger.debug "#{type} Attributes: " + "#{attrs}".yellow
    end

    # TODO: Single Responsibility Principle drops badly here.
    # Please consider splitting this to separate error handlers sub-classes
    # https://github.com/hndsm/j2p/issues/58
    def error_log(exception)
      if exception.instance_of?(JIRA::HTTPError)
        logger.error exception.response
      elsif exception.instance_of?(TrackerApi::Error)
        logger.error exception.response
      else
        logger.error exception.message
      end

      logger.error exception.backtrace.inspect
    end

    private

    def formatter
      proc do |severity, datetime, _progname, msg|
        if severity == 'INFO' || severity == 'WARN'
          if config['sync_action'] == 'INVOICED'
            invoiced_action(datetime, msg)
          else
            update_create_action(datetime, msg)
          end
        else
          other_action(severity, datetime, msg)
        end
      end
    end

    def invoiced_action(datetime, msg)
      "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{config['process_pid']} P##{config['project_name']}] " +
        "#{config['sync_action']}".green + " -- #{msg}\n"
    end

    def update_create_action(datetime, msg)
      "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{config['process_pid']} P##{config['project_name']}]   " +
        "#{config['sync_action']}".green + " -- #{msg}\n"
    end

    def other_action(severity, datetime, msg)
      "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{config['process_pid']} P##{config['project_name']}]    " +
        "#{severity}".red + " -- #{msg}\n"
    end
  end
end
