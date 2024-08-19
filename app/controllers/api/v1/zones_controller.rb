class Api::V1::ZonesController < Api::ApiController
  def create_subdomain
    if DnsZone.create_subdomain(zone_params)
      zone = DnsZone.find_by(name: zone_params[:name])
      render json: { id: zone.id, name: zone.name }, status: :created
    else
      render json: { errors: zone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_acme_challenge
    zone = DnsZone.find_by(name: zone_params[:name])
    record = zone.dns_records.create(name: '@', record_type: DnsRecord::TXT, data: zone_params[:data], ttl: '300')
    if record.save
      render json: { id: record.id, name: record.name, data: record.data }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete_acme_challenge
    zone = DnsZone.find_by(name: zone_params[:name])
    record = zone.dns_records.find_by(name: '@', record_type: DnsRecord::TXT, data: zone_params[:data])
    if record.destroy
      render json: { id: record.id, name: record.name, data: record.data }, status: :ok
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def zone_params
    params.require(:zone).permit(:name, :data) # Replace with actual permitted params
  end
end
