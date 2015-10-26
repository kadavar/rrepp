class BaseController < ApplicationController
  before_filter :authenticate

  protected

  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == "jetruby" && password == "jetruby123!"
    end
  end
end
