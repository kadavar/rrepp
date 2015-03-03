class JiraToPivotal::Base
  def logger
    @logger ||= JiraToPivotal::ScriptLogger.new(@config)
  end
end
