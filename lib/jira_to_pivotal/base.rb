module JiraToPivotal
  class Base
    include Retryable
    include ErrorsHandler

    def init_logger(config)
      logger = JiraToPivotal::ScriptLogger.instance
      logger.config = config
      logger.init_logger
    end

    def logger
      JiraToPivotal::ScriptLogger.instance
    end
  end
end
