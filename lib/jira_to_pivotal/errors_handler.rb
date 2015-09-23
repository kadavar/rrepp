module JiraToPivotal
  module ErrorsHandler
    def airbrake_report_and_log(error, params = {})
      airbrake_params = { cgi_data: ENV.to_hash }
      airbrake_params[:parameters] = params[:parameters] if params[:parameters]

      Airbrake.notify_or_ignore(error, airbrake_params) unless params[:skip_airbrake]

      logger.error_log(error)
    end
  end
end
