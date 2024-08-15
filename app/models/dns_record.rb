class DnsRecord < ApplicationRecord
  belongs_to :dns_zone
  validates :name, presence: true
  validates :data, presence: true
  validates :name, uniqueness: { scope: :data, message: 'already exists' }

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

  # adds dns record to zone
  def add_a # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    zone_name = dns_zone.name
    zone_name += '.' unless dns_zone.name.end_with?('.')
    dns_records = dns_zone.dns_records.where(name: name, record_type: DnsRecord::A)
    a = []
    dns_records.each do |dns_record|
      a << {
        ip: dns_record.data,
        ttl: dns_record.time_to_live
      }
    end

    record = { a: a }
    redis = Redis.new(host: dns_zone.redis_host)
    redis.hset(zone_name, name, record.to_json)
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
end
