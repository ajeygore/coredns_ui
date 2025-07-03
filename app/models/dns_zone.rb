# frozen_string_literal: true

class DnsZone < ApplicationRecord # rubocop:disable Style/Documentation
  has_many :dns_records, dependent: :destroy
  validates_uniqueness_of :name
  # before_validation :check_if_subdomain_of_existing_domain, on: :create

  # after_save :refesh_coredns disabling this, since now coredns can reload zones on its own.

  def refesh_coredns
    pid = `sudo pgrep coredns`.strip

    return unless pid.present?

    result = system("sudo kill -USR1 #{pid}")
    Rails.logger.info("CoreDNS has been reloaded successfully PID: #{pid} Result: #{result}")
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
    a = prepare_a record_name
    ns = prepare_ns record_name
    txt = prepare_txt record_name
    cname_data = prepare_cname record_name
    response_hash = {}
    response_hash[:a] = a unless a.nil?
    response_hash[:ns] = ns unless ns.nil?
    response_hash[:txt] = txt unless txt.nil?
    
    unless cname_data.nil?
      cname_record = dns_records.where(name: record_name, record_type: DnsRecord::CNAME).first
      response_hash[:cname] = [{
        host: cname_data,
        ttl: cname_record.time_to_live.to_i
      }]
    end

    response_hash
  end

  def update_redis(record_name)
    redis = Redis.new(host: redis_host)
    redis.hdel("#{name}.", record_name)
    record = prepare_records(record_name)
    redis.hset("#{name}.", record_name, record.to_json) if record.count.positive?
  end

  def zone_name_add_acme_challenge
  end

  def prepare_a(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::A)
    return nil if records.count.zero?

    a = []
    records.each do |record|
      a << { ip: record.data, ttl: record.time_to_live.to_i }
    end
    a
  end

  def prepare_ns(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::NS)
    return nil if records.count.zero?

    ns = []
    records.each do |record|
      ns << { host: record.data, ttl: record.time_to_live.to_i }
    end
    ns
  end

  def prepare_txt(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::TXT)
    return nil if records.count.zero?

    txt = []
    records.each do |record|
      txt << { text: record.data, ttl: record.time_to_live.to_i }
    end
    txt
  end

  def prepare_cname(record_name)
    records = dns_records.where(name: record_name, record_type: DnsRecord::CNAME)
    # For CNAME, typically there should be only one record.
    return nil if records.empty?
    record = records.first
    record.data
  end

  def self.create_subdomain(params)
    zone = DnsZone.create(name: params[:name], redis_host: 'localhost')
    zone.dns_records.create(name: '@', record_type: DnsRecord::A, data: params[:data],
                            ttl: '300') if params[:data].present?
    zone.dns_records.create(name: '*', record_type: DnsRecord::A, data: params[:data],
                            ttl: '300') if params[:data].present?
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

  def check_if_subdomain_of_existing_domain
    unless parent_domain_exists?
      errors.add(:base, "The domain '#{name}' is not a subdomain of an existing domain")
    end
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
