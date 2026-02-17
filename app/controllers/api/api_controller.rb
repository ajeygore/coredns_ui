class Api::ApiController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api

  private

  def authenticate_api
    token = request.headers['Authorization']
    @current_api_token = ApiToken.find_by(token: token)

    return unless @current_api_token.nil?

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def authorize_api_zone_access!(zone_name)
    return if @current_api_token.can_access_zone_name?(zone_name)

    render json: { error: 'Forbidden: token does not have access to this zone' }, status: :forbidden
  end
end
