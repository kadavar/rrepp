module JiraToPivotal
  module Retryable
    def retryable(options = {}, &block)
      opts =
      {
        on: Exception,
        can_fail: false,
        returns: false,
        with_delay: false,
        try: config['retry_count'].to_i,
        delay: config['repeat_delay'].to_i,
        skip_airbrake: false
      }.merge(options)

      retry_exception = opts[:on]
      retries = opts[:try]
      delay = opts[:delay]

      begin
        yield

      # Temp, until logger refactoring
      rescue retry_exception, SocketError, TrackerApi::Error => e
        skip_airbrake = e.class == SocketError || TrackerApi::Error ? true : opts[:skip_airbrake]

        report_params = {
          parameters: config.airbrake_message_parameters,
          skip_airbrake: skip_airbrake
        }

        airbrake_report_and_log e, report_params

        sleep delay if opts[:with_delay]

        retry unless (retries -= 1) <= 0

        can_fail = opts[:can_fail] && !(e.class == SocketError || e.class == TrackerApi::Error)

        fail e if can_fail

        opts[:returns]
      end
    end
  end
end
