require 'retryable'

module JiraToPivotal
  class Base
    include Retryable
    def logger
      @logger ||= JiraToPivotal::ScriptLogger.new(@config)
    end
  end
end
