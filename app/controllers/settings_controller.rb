class SettingsController < ApplicationController
  before_action :require_admin

  def show
    @settings = {}
    ServerSetting::KEYS.each { |k| @settings[k] = ServerSetting.get(k) }
  end

  def update
    ServerSetting::KEYS.each do |key|
      ServerSetting.set(key, params[key]) if params.key?(key)
    end
    redirect_to settings_path, notice: 'Settings saved.'
  end

  def backup
    data = {
      exported_at: Time.current.iso8601,
      zones: DnsZone.all.map do |zone|
        {
          name: zone.name,
          redis_host: zone.redis_host,
          records: zone.dns_records.map do |r|
            { record_type: r.record_type, name: r.name, data: r.data, ttl: r.ttl }
          end
        }
      end
    }
    send_data data.to_json, filename: "coredns_backup_#{Date.current}.json",
              type: 'application/json'
  end

  def restore
    file = params[:backup_file]
    unless file
      redirect_to settings_path, alert: 'No file selected.'
      return
    end

    data = JSON.parse(file.read)
    imported = 0
    data['zones'].each do |zone_data|
      zone = DnsZone.find_or_create_by!(name: zone_data['name']) do |z|
        z.redis_host = zone_data['redis_host']
      end
      zone_data['records'].each do |rec|
        zone.dns_records.find_or_create_by!(
          record_type: rec['record_type'],
          name: rec['name'],
          data: rec['data']
        ) { |r| r.ttl = rec['ttl'] }
        imported += 1
      end
      zone.refresh
    end
    redirect_to settings_path, notice: "Restored #{imported} records."
  rescue JSON::ParserError
    redirect_to settings_path, alert: 'Invalid backup file format.'
  end
end
