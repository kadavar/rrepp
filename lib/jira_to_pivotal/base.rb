module JiraToPivotal
  class Base
    def logger
      @logger ||= JiraToPivotal::ScriptLogger.new(@config)
    end
  end
end
