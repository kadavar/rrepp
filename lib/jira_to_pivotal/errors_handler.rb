module JiraToPivotal
  class ErrorsHandler
    class << self
      def airbrake_report_and_log(error, params = {})
        airbrake_params = { cgi_data: ENV.to_hash }
        airbrake_params[:parameters] = params[:parameters] if params[:parameters]
        airbrake_params[:error_message] = params[:error_message] if params[:error_message]

        Airbrake.notify_or_ignore(error, airbrake_params) unless params[:skip_airbrake]

        logger.error_log(error)
      end
    end
  end
end
