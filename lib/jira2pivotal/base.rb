module Jira2Pivotal
  class Base
    def logger
      @logger ||= Jira2Pivotal::Loger.new(@config)
    end
  end
end
