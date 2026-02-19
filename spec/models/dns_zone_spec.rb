require 'rails_helper'

RSpec.describe DnsZone, type: :model do
  it 'should add a dns record of type a' do
    dns_zone = DnsZone.create(name: 'example.com', redis_host: 'localhost')
    dns_record = DnsRecord.create(name: 'www', record_type: DnsRecord::A, data: '1.1.1.1')
    dns_zone.dns_records << dns_record
    expect(dns_zone.dns_records.count).to eq(1)
  end

  describe '#zone_records' do
    let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }
    let(:redis_mock) { instance_double(Redis) }

    before do
      allow(Redis).to receive(:new).with(host: 'localhost').and_return(redis_mock)
    end

    it 'returns an empty array when Redis has no records' do
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return({})
      expect(dns_zone.zone_records).to eq([])
    end

    it 'parses A records from Redis' do
      redis_data = { 'www' => { 'a' => [{ 'ip' => '1.1.1.1', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: 'www', type: 'A', data: '1.1.1.1', ttl: 300 }])
    end

    it 'parses NS records from Redis' do
      redis_data = { '@' => { 'ns' => [{ 'host' => 'ns1.example.com.', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: '@', type: 'NS', data: 'ns1.example.com.', ttl: 300 }])
    end

    it 'parses CNAME records from Redis' do
      redis_data = { 'cdn' => { 'cname' => [{ 'host' => 'cdn.example.com.', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: 'cdn', type: 'CNAME', data: 'cdn.example.com.', ttl: 300 }])
    end

    it 'parses MX records from Redis' do
      redis_data = { '@' => { 'mx' => [{ 'priority' => 10, 'host' => 'mail.example.com.', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: '@', type: 'MX', data: '10 mail.example.com.', ttl: 300 }])
    end

    it 'parses TXT records from Redis' do
      redis_data = { '@' => { 'txt' => [{ 'text' => 'v=spf1 include:example.com ~all', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: '@', type: 'TXT', data: 'v=spf1 include:example.com ~all', ttl: 300 }])
    end

    it 'parses multiple record types for a single name' do
      redis_data = {
        'www' => {
          'a' => [{ 'ip' => '1.1.1.1', 'ttl' => 300 }],
          'ns' => [{ 'host' => 'ns1.example.com.', 'ttl' => 300 }]
        }.to_json
      }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      types = records.map { |r| r[:type] }
      expect(types).to contain_exactly('A', 'NS')
    end

    it 'parses multiple names from Redis' do
      redis_data = {
        'www' => { 'a' => [{ 'ip' => '1.1.1.1', 'ttl' => 300 }] }.to_json,
        'mail' => { 'a' => [{ 'ip' => '2.2.2.2', 'ttl' => 300 }] }.to_json
      }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      names = records.map { |r| r[:name] }
      expect(names).to contain_exactly('www', 'mail')
    end
  end
end
