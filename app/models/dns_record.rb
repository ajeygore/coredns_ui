class DnsRecord < ApplicationRecord
  belongs_to :dns_zone
  before_validation :strip_whitespace
  validates :name, presence: true
  validates :data, presence: true
  validates :record_type, presence: true
  validates :name, uniqueness: { scope: %i[data dns_zone_id], message: 'already exists' }

  A = 'A'.freeze
  AAAA = 'AAAA'.freeze
  CNAME = 'CNAME'.freeze
  TXT = 'TXT'.freeze
  MX = 'MX'.freeze
  NS = 'NS'.freeze
  PTR = 'PTR'.freeze
  SRV = 'SRV'.freeze
  SOA = 'SOA'.freeze
  SPF = 'SPF'.freeze
  SSHFP = 'SSHFP'.freeze
  TLSA = 'TLSA'.freeze
  URI = 'URI'.freeze
  SMIMEA = 'SMIMEA'.freeze

  def time_to_live
    return 300 if ttl.nil?

    ttl
  end

  def update_redis
    method_name = "add_#{record_type.downcase}"
    raise "Unknown record type: #{record_type}" unless respond_to?(method_name)

    send(method_name)
  end

  def add_a
    record = { a: prepare_a }
    zone_name = "#{dns_zone.name}." unless dns_zone.name.end_with?('.')
    redis = Redis.new(host: dns_zone.redis_host)
    redis.hset(zone_name, name, record.to_json)
  end

  def prepare_a_data
    unique_records = DnsRecord.distinct.pluck(:name)
    unique_records.each do |record_name|
      prepare_a record_name
    end
  end

  def prepare_a(record_name)
    dns_records = dns_zone.dns_records.where(name: record_name, record_type: DnsRecord::A)
    a = []
    dns_records.each do |dns_record|
      a << { ip: dns_record.data, ttl: dns_record.time_to_live.to_i }
    end
    a
  end

  def add_cname
    # For a CNAME record, the data should be the canonical domain name.
    existing_record = dns_zone.dns_records.find_by(name: name, record_type: DnsRecord::CNAME)
    if existing_record.present?
      raise "CNAME record for '#{name}' already exists with data '#{existing_record.data}'"
    end

    record = { cname: data, ttl: time_to_live.to_i }
    zone_name = dns_zone.name.end_with?('.') ? dns_zone.name : "#{dns_zone.name}."
    redis = Redis.new(host: dns_zone.redis_host)
    redis.hset(zone_name, name, record.to_json)
  end

  def prepare_cname
    records = dns_zone.dns_records.where(name: name, record_type: DnsRecord::CNAME)
    # In standard DNS, there should be one CNAME per alias.
    if records.present?
      record = records.first
      { cname: record.data, ttl: record.time_to_live.to_i }
    end
  end

  def del_a
    zone_name = dns_zone.name
    zone_name += '.' unless dns_zone.name.end_with?('.')

    redis = Redis.new(host: dns_zone.redis_host)
    address_hash = JSON.parse(redis.hget(zone_name, name))
    address_hash['a'].delete_if { |a| a['ip'] == data }
    redis.hset(zone_name, name, address_hash.to_json)
  end

  def add_aaaa
    zone_name = dns_zone.name
    zone_name += '.' unless dns_zone.name.end_with?('.')
    record = {
      aaaa: [
        ip6: value,
        ttl: time_to_live
      ]
    }
    REDIS.hset(zone_name, name, record.to_json)
  end

  private

  def strip_whitespace
    self.name = name.strip unless name.nil?
    self.data = data.strip unless data.nil?
  end
end
