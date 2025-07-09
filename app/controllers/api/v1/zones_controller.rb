class Api::V1::ZonesController < Api::ApiController
  def create_subdomain
    if DnsZone.create_subdomain(zone_params)
      zone = DnsZone.find_by(name: zone_params[:name])
      zone.refresh
      render json: { id: zone.id, name: zone.name }, status: :created
    else
      render json: { errors: zone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create_acme_challenge
    zone = DnsZone.find_by(name: zone_params[:name])

    record = zone.dns_records.create(name: '_acme-challenge', record_type: DnsRecord::TXT, data: zone_params[:data],
                                     ttl: '300')
    if record.save
      zone.refresh
      render json: { id: record.id, name: record.name, data: record.data }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_a
    zone = DnsZone.find_by(name: zone_params[:name])
    record_data = zone_params[:data].split(',')
    record = zone.dns_records.find_or_initialize_by(name: record_data[0], record_type: DnsRecord::A, ttl: '300')
    record.data = record_data[1]
    if record.save
      zone.refresh
      render json: { id: record.id, name: record.name, data: record.data }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete_acme_challenge
    zone = DnsZone.find_by(name: zone_params[:name])
    record = zone.dns_records.find_by(name: '_acme-challenge', record_type: DnsRecord::TXT)
    if record.destroy
      zone.update_redis(record.name)
      render json: { id: record.id, name: record.name, data: record.data }, status: :ok
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete_subdomain
    if DnsZone.delete_subdomain(zone_params)
      render json: { name: zone_params[:name] }, status: :ok
    else
      render json: { errors: zone.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_mx
    zone = DnsZone.find_by(name: zone_params[:name])
    return render json: { errors: ['Zone not found'] }, status: :not_found unless zone

    mx_data = "#{mx_params[:priority]} #{mx_params[:host]}"
    record = zone.dns_records.create(
      name: mx_params[:record_name] || '@',
      record_type: DnsRecord::MX,
      data: mx_data,
      ttl: mx_params[:ttl] || 300
    )

    if record.save
      zone.refresh
      render json: {
        id: record.id,
        name: record.name,
        data: record.data,
        priority: mx_params[:priority],
        host: mx_params[:host],
        ttl: record.ttl
      }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete_mx
    zone = DnsZone.find_by(name: zone_params[:name])
    return render json: { errors: ['Zone not found'] }, status: :not_found unless zone

    mx_data = "#{mx_params[:priority]} #{mx_params[:host]}"
    record = zone.dns_records.find_by(
      name: mx_params[:record_name] || '@',
      record_type: DnsRecord::MX,
      data: mx_data
    )

    return render json: { errors: ['MX record not found'] }, status: :not_found unless record

    if record.destroy
      zone.update_redis(record.name)
      render json: {
        id: record.id,
        name: record.name,
        data: record.data,
        priority: mx_params[:priority],
        host: mx_params[:host]
      }, status: :ok
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.

  def zone_params
    params.require(:zone).permit(:name, :data)
  end

  def mx_params
    params.require(:mx).permit(:priority, :host, :record_name, :ttl)
  end
end
