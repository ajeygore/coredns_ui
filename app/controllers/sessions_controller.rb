class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[create destroy]

  def create
    auth = request.env['omniauth.auth']
    unless auth.info.email.split('@').last == 'soracloud.ai'
      redirect_to root_path, alert: 'You are not authorized, please contact admins.'
      return
    end
    @user = User.from_omniauth(request.env['omniauth.auth'])
    session[:user_id] = @user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path
  end
end
