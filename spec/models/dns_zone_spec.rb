require 'rails_helper'

RSpec.describe DnsZone, type: :model do
  it "should add a dns record of type a" do
    dns_zone = DnsZone.create(name: 'example.com', redis_host: 'localhost')
    dns_record = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: "1.1.1.1")
    dns_zone.dns_records << dns_record
    expect(dns_zone.dns_records.count).to eq(1)
  end
end
