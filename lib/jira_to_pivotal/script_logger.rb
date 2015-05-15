class JiraToPivotal::ScriptLogger
  def initialize(config)
    @config = config

    logger.formatter = formatter
    logger
  end

  def logger
    @logger ||= Logger.new("log/#{@config['log_file_name']}")
  end

  def jira_logger
    @jira_logger ||= JiraToPivotal::Loggs::JiraLogger.new(logger, @config)
  end

  def attrs_log(attrs, type='Before save')
    logger.debug "#{type} Attributes: " + "#{attrs}".yellow
  end

  def error_log(exception)
    if exception.instance_of? JIRA::HTTPError
      logger.error exception.response.body
    else
      logger.error exception.message
    end

    logger.error exception.backtrace.inspect
  end

  private

  def formatter
    proc do |severity, datetime, progname, msg|
      if severity == 'INFO' || severity == 'WARN'
        if @config['sync_action'] == 'INVOICED'
          "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{@config['process_pid']} P##{@config['project_name']}] " + "#{@config['sync_action']}".green + " -- #{msg}\n"
        else
          "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{@config['process_pid']} P##{@config['project_name']}]   " + "#{@config['sync_action']}".green +  " -- #{msg}\n"
        end
      else
        "[#{datetime.utc.strftime('%Y-%m-%d %H:%M:%S.%6N %Z')} ##{@config['process_pid']} P##{@config['project_name']}]    " + "#{severity}".red + " -- #{msg}\n"
      end
    end
  end
end
