class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :require_login, except: %i[login]

  helper_method :current_user, :logged_in?
  def login; end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    !!current_user
  end

  def require_login
    return if logged_in?

    redirect_to login_path, alert: 'You must be logged in to access this page.'
  end
end
