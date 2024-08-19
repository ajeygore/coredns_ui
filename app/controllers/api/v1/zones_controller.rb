class Api::V1::ZonesController < Api::ApiController
  def create_subdomain
    if DnsZone.create_subdomain(zone_params)
      zone = DnsZone.find_by(name: zone_params[:name])
      render json: { id: zone.id, name: zone.name }, status: :created
    else
      render json: { errors: zone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def zone_params
    params.require(:zone).permit(:name, :ip_address) # Replace with actual permitted params
  end
end
