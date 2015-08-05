module JiraToPivotal
  module Retryable
    def retryable(options = {}, &block)
      opts = { tries: 1, on: Exception, logger: logger, can_fail: false }.merge(options)
      binding.pry
      retry_exception = opts[:on]
      retries = opts[:tries]
      logger = opts[:logger]
      can_fail = opts[:can_fail]
      begin
        super
      rescue retry_exception => e
        logger.error_log(e)
        Airbrake.notify_or_ignore(e, parameters: @config.airbrake_message_parameters, cgi_data: ENV.to_hash)

        fail e if can_fail

        retry unless (retries -= 1).zero?
        false
      end

      yield
    end
  end
end
