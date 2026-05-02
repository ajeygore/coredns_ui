class Api::V1::ZonesController < Api::ApiController
  before_action :check_api_zone_permission

  def create_subdomain
    if DnsZone.create_subdomain(zone_params)
      zone = DnsZone.find_by(name: zone_params[:name])
      zone.refresh
      render json: { id: zone.id, name: zone.name }, status: :created
    else
      render json: { errors: ["Failed to create subdomain"] }, status: :unprocessable_entity
    end
  end

  def create_acme_challenge
    zone = DnsZone.find_by(name: zone_params[:name])

    challenge_name = zone_params[:record_name].presence || '_acme-challenge'
    # TTL=1 so the global `cache` plugin in Corefile only holds these records
    # (and their NXDOMAIN siblings) for ~1s — otherwise the present→validate
    # window during ACME flows can serve a stale cached value to the CA.
    record = zone.dns_records.create(name: challenge_name, record_type: DnsRecord::TXT, data: zone_params[:data],
                                     ttl: '1')
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
    challenge_name = zone_params[:record_name].presence || '_acme-challenge'
    # `find_by` returned only the first match, leaving siblings behind when
    # a previous lego run ordered SAN+wildcard against the same record_name.
    # Destroy ALL matches and do a full zone.refresh so Redis is in sync —
    # update_redis(name) was a per-name partial sync that didn't write the
    # zero-records case (Redis kept the deleted record's old value).
    destroyed = zone.dns_records.where(name: challenge_name, record_type: DnsRecord::TXT).destroy_all
    zone.refresh
    render json: { count: destroyed.size, name: challenge_name }, status: :ok
  end

  def delete_subdomain
    if DnsZone.delete_subdomain(zone_params)
      render json: { name: zone_params[:name] }, status: :ok
    else
      render json: { errors: ["Zone not found"] }, status: :not_found
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

  def add_soa
    zone = DnsZone.find_by(name: zone_params[:name])
    return render json: { errors: ['Zone not found'] }, status: :not_found unless zone

    soa_data = "#{soa_params[:ns]} #{soa_params[:mbox]} #{soa_params[:refresh] || 3600} #{soa_params[:retry] || 600} #{soa_params[:expire] || 86400} #{soa_params[:minttl] || 300}"
    record = zone.dns_records.find_or_initialize_by(
      name: soa_params[:record_name] || '@',
      record_type: DnsRecord::SOA
    )
    record.data = soa_data
    record.ttl = soa_params[:ttl] || 3600

    if record.save
      zone.refresh
      render json: {
        id: record.id,
        name: record.name,
        data: record.data,
        ttl: record.ttl
      }, status: :created
    else
      render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete_soa
    zone = DnsZone.find_by(name: zone_params[:name])
    return render json: { errors: ['Zone not found'] }, status: :not_found unless zone

    record = zone.dns_records.find_by(
      name: zone_params[:record_name] || '@',
      record_type: DnsRecord::SOA
    )
    return render json: { errors: ['SOA record not found'] }, status: :not_found unless record

    if record.destroy
      zone.update_redis(record.name)
      render json: { id: record.id, name: record.name }, status: :ok
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
    params.require(:zone).permit(:name, :data, :record_name)
  end

  def mx_params
    params.require(:mx).permit(:priority, :host, :record_name, :ttl)
  end

  def soa_params
    params.require(:soa).permit(:ns, :mbox, :refresh, :retry, :expire, :minttl, :record_name, :ttl)
  end

  def check_api_zone_permission # rubocop:disable Metrics/AbcSize
    zone_name = zone_params[:name] if params[:zone].present?
    zone_name ||= mx_params[:name] if params[:mx].present? && mx_params[:name].present?
    zone_name ||= params.dig(:soa, :zone_name) if params[:soa].present?

    return if zone_name.blank?

    authorize_api_zone_access!(zone_name)
  end
end
