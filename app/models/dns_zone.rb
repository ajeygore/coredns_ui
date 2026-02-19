# frozen_string_literal: true

class DnsZone < ApplicationRecord
  has_many :dns_records, dependent: :destroy
  validates_uniqueness_of :name
  # before_validation :check_if_subdomain_of_existing_domain, on: :create

  # after_save :refesh_coredns disabling this, since now coredns can reload zones on its own.

  REDIS_TYPE_PARSERS = {
    'a' => ->(v) { v['ip'] },
    'ns' => ->(v) { v['host'] },
    'cname' => ->(v) { v['host'] },
    'mx' => ->(v) { "#{v['priority']} #{v['host']}" },
    'txt' => ->(v) { v['text'] },
    'aaaa' => ->(v) { v['ip6'] }
  }.freeze

  def refesh_coredns
    pid = `sudo pgrep coredns`.strip

    return unless pid.present?

    result = system("sudo kill -USR1 #{pid}")
    Rails.logger.info("CoreDNS has been reloaded successfully PID: #{pid} Result: #{result}")
  end

  # Reads all records from Redis for this zone and returns a flat array of record hashes
  def zone_records
    redis = Redis.new(host: redis_host)
    zone_key = name.end_with?('.') ? name : "#{name}."
    redis.hgetall(zone_key).flat_map do |record_name, json|
      parse_redis_entry(record_name, JSON.parse(json))
    end
  end

  def self.refresh_zones
    DnsZone.all.each(&:refresh)
  end

  def refresh
    unique_records = dns_records.distinct.pluck(:name)
    redis = Redis.new(host: redis_host)
    redis.del("#{name}.")
    unique_records.each do |record_name|
      redis.hset("#{name}.", record_name, prepare_records(record_name).to_json)
    end
  end

  def prepare_records(record_name)
    response_hash = {}
    response_hash[:a] = prepare_a(record_name)
    response_hash[:ns] = prepare_ns(record_name)
    response_hash[:txt] = prepare_txt(record_name)
    response_hash[:mx] = prepare_mx(record_name)
    response_hash.compact!
    append_cname_records(response_hash, record_name)
    response_hash
  end

  def update_redis(record_name)
    redis = Redis.new(host: redis_host)
    redis.hdel("#{name}.", record_name)
    record = prepare_records(record_name)
    redis.hset("#{name}.", record_name, record.to_json) if record.any?
  end

  def zone_name_add_acme_challenge; end

  def prepare_a(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::A)
    return nil if records.none?

    records.map { |record| { ip: record.data, ttl: record.time_to_live.to_i } }
  end

  def prepare_ns(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::NS)
    return nil if records.none?

    records.map { |record| { host: record.data, ttl: record.time_to_live.to_i } }
  end

  def prepare_txt(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::TXT)
    return nil if records.none?

    records.map { |record| { text: record.data, ttl: record.time_to_live.to_i } }
  end

  def prepare_cname(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::CNAME)
    # For CNAME, typically there should be only one record.
    return nil if records.empty?

    record = records.first
    record.data
  end

  def prepare_mx(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::MX)
    return nil if records.none?

    records.map do |record|
      parts = record.data.split(' ', 2)
      { priority: Integer(parts[0]), host: parts[1], ttl: record.time_to_live.to_i }
    end
  end

  def self.create_subdomain(params)
    zone = DnsZone.create(name: params[:name], redis_host: ENV.fetch('REDIS_HOST', 'localhost'))
    if params[:data].present?
      zone.dns_records.create(name: '@', record_type: DnsRecord::A, data: params[:data],
                              ttl: '300')
    end
    return unless params[:data].present?

    zone.dns_records.create(name: '*', record_type: DnsRecord::A, data: params[:data],
                            ttl: '300')
  end

  def self.delete_subdomain(params)
    zone = DnsZone.find_by(name: params[:name])
    return false if zone.nil?

    zone.dns_records.destroy_all

    redis = Redis.new(host: zone.redis_host)
    redis.del("#{zone.name}.")
    zone.destroy
  end

  def self.create_acme_challenge(params)
    zone = DnsZone.find_by(name: params[:name])
    return false if zone.nil?

    zone.dns_records.create(name: '_acme-challenge', record_type: DnsRecord::A, data: params[:data], ttl: '300')
  end

  private

  def append_cname_records(response_hash, record_name)
    cname_data = prepare_cname(record_name)
    return if cname_data.nil?

    cname_record = dns_records.where(name: record_name, record_type: DnsRecord::CNAME).first
    response_hash[:cname] = [{ host: cname_data, ttl: cname_record.time_to_live.to_i }]

    resolved_ip = resolve_cname_to_ip(cname_data)
    return unless resolved_ip

    response_hash[:a] ||= []
    response_hash[:a] << { ip: resolved_ip, ttl: cname_record.time_to_live.to_i }
  end

  def parse_redis_entry(record_name, data)
    data.flat_map do |type_key, value|
      parser = REDIS_TYPE_PARSERS[type_key]
      next [] unless parser

      Array(value).map do |v|
        { name: record_name, type: type_key.upcase, data: parser.call(v), ttl: v['ttl'] }
      end
    end
  end

  def resolve_cname_to_ip(hostname)
    require 'resolv'
    begin
      Resolv.getaddress(hostname)
    rescue StandardError => e
      Rails.logger.warn("Failed to resolve CNAME #{hostname}: #{e.message}")
      nil
    end
  end

  def check_if_subdomain_of_existing_domain
    return if parent_domain_exists?

    errors.add(:base, "The domain '#{name}' is not a subdomain of an existing domain")
  end

  def parent_domain_exists?
    parts = name.split('.')

    # Start checking from the immediate parent and go upwards
    while parts.size > 1
      parts.shift
      potential_parent = parts.join('.')

      return true if DnsZone.exists?(name: potential_parent)
    end

    false
  end
end
