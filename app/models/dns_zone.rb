class DnsZone < ApplicationRecord
  has_many :dns_records, dependent: :destroy
  validates_uniqueness_of :name

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
    response_hash = {}
    response_hash[:a] = a unless a.nil?
    response_hash[:ns] = ns unless ns.nil?
    response_hash[:txt] = txt unless txt.nil?

    response_hash
  end

  def update_redis(record_name)
    redis = Redis.new(host: redis_host)
    redis.hdel("#{name}.", record_name)
    record = prepare_records(record_name)
    redis.hset("#{name}.", record_name, record.to_json)
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
      txt << { host: record.data, ttl: record.time_to_live.to_i }
    end
    txt
  end
end
