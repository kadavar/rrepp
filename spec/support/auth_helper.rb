module AuthHelper
  def auth_user
    @user = 'jetruby'
  end

  def auth_password
    @pw = 'jetruby123!'
  end

  def http_login
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(auth_user, auth_password)
  end
end