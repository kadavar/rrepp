module JiraToPivotal
  class Base
    include Retryable
    include ErrorsHandler

    def logger
      @logger ||= JiraToPivotal::ScriptLogger.new(config)
    end
  end
end
