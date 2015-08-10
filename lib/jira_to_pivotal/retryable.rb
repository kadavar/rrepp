module JiraToPivotal
  module Retryable
    def retryable(options = {}, &block)
      opts = { on: Exception, can_fail: false, returns: false }.merge(options)

      retry_exception = opts[:on]
      retries = opts[:try].present? ? opts[:try] : config['script_repeat_time'].to_i
      logger = opts[:logger]
      can_fail = opts[:can_fail]
      begin
        yield

      rescue retry_exception => e
        logger.error_log(e)
        Airbrake.notify_or_ignore(e, parameters: @config.airbrake_message_parameters, cgi_data: ENV.to_hash)
        retry unless (retries -= 1).zero?

        fail e if can_fail

        opts[:returns]
      end
    end
  end
end
