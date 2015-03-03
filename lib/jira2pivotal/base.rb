module Jira2Pivotal
  class Base
    def logger
      @logger ||= Jira2Pivotal::ScriptLogger.new(@config)
    end
  end
end
