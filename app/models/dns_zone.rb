class DnsZone < ApplicationRecord
  has_many :dns_records, dependent: :destroy
  validates_uniqueness_of :name

  def self.refresh_zones
    DnsZone.all.each(&:refresh)
  end

  def refresh
    redis = Redis.new(host: redis_host)
    redis.del("#{name}.")
    dns_records.each do |dns_record|
      dns_record.add_a if dns_record.record_type == DnsRecord::A
    end
  end
end
