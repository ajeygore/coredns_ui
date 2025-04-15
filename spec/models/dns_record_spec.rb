require 'rails_helper'

RSpec.describe DnsRecord, type: :model do
  it "should add a dns record of type a" do
    dns_zone = DnsZone.create(name: 'example.com', redis_host: 'localhost')
    dns_record = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: "1.1.1.1")
    dns_zone.dns_records << dns_record

    expect(dns_zone.dns_records.count).to eq(1)
    dns_record_data = [
      { ip: '1.1.1.1', ttl: 300 }
    ]
    expect(dns_record_data).to eq(dns_zone.prepare_a('www'))
    dns_record = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: "1.1.1.2")
    dns_zone.dns_records << dns_record
    dns_record_data << { ip: '1.1.1.2', ttl: 300 }
    expect(dns_record_data).to eq(dns_zone.prepare_a('www'))
    zone_data = { a: dns_record_data }
    expect(zone_data).to eq(dns_zone.prepare_records('www'))
  end

  it 'should add a dns_record type of a and ns' do # rubocop:disable Metrics/BlockLength
    dns_zone = DnsZone.create(name: 'example.com', redis_host: 'localhost')
    dns_record = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: "1.1.1.1")
    dns_record_ns = DnsRecord.create(name: 'www', record_type: DnsRecord::NS, data: 'ns1.example.com')
    dns_zone.dns_records << dns_record
    dns_zone.dns_records << dns_record_ns
    dns_record_a_data = [
      { ip: '1.1.1.1', ttl: 300 }
    ]
    dns_record_ns_data = [
      { host: 'ns1.example.com', ttl: 300 }
    ]
    expect(dns_record_a_data).to eq(dns_zone.prepare_a('www'))
    expect(dns_record_ns_data).to eq(dns_zone.prepare_ns('www'))
    zone_data = { a: dns_record_a_data, ns: dns_record_ns_data }
    expect(zone_data).to eq(dns_zone.prepare_records('www'))
    dns_record_a = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: "1.1.1.2")
    dns_zone.dns_records << dns_record_a
    ans_record_a_data = [
      { ip: '1.1.1.1', ttl: 300 },
      { ip: '1.1.1.2', ttl: 300 }
    ]
    expect(ans_record_a_data).to eq(dns_zone.prepare_a('www'))
    zone_data = { a: ans_record_a_data, ns: dns_record_ns_data }
    expect(zone_data).to eq(dns_zone.prepare_records('www'))

    dns_record_ns = DnsRecord.create(name: 'www1', record_type: DnsRecord::NS, data: 'ns2.example.com')
    dns_zone.dns_records << dns_record_ns
    dns_record_www1_data = { host: 'ns2.example.com', ttl: 300 }
    zone_data = { ns: [dns_record_www1_data] }
    expect(zone_data).to eq(dns_zone.prepare_records('www1'))
  end

  it "creates and processes a CNAME record correctly" do
    dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
    cname_record = dns_zone.dns_records.create!(name: 'alias', record_type: DnsRecord::CNAME, data: "canonical.example.com")
    
    # Check that the record is valid and exists
    expect(dns_zone.dns_records.count).to eq(1)
    expect(cname_record.record_type).to eq("CNAME")
    
    # Test the helper method from the zone
    prepared_cname = dns_zone.prepare_cname('alias')
    expect(prepared_cname).to eq({ cname: "canonical.example.com", ttl: 300 })
  end
end
