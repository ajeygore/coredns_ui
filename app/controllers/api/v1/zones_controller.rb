class Api::V1::ZonesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_api

  private

  def authenticate_api
    token = request.headers['Authorization']
    api_token = ApiToken.find_by(token: token)

    return unless api_token.nil? || api_token.expired?

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  def resource_params
    params.require(:your_resource).permit(:attribute1, :attribute2) # Replace with actual permitted params
  end
end
