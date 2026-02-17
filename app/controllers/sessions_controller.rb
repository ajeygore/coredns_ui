class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[create destroy]

  def create
    auth = request.env['omniauth.auth']
    @user = User.from_omniauth(auth)

    if @user.nil?
      redirect_to login_path, alert: 'You are not authorized. Please contact an admin for access.'
      return
    end

    session[:user_id] = @user.id
    redirect_to root_path
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path
  end
end
