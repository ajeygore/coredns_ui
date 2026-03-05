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
      redis_data = { '@' => { 'mx' => [{ 'preference' => 10, 'host' => 'mail.example.com.', 'ttl' => 300 }] }.to_json }
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

    it 'parses AAAA records from Redis' do
      redis_data = { 'www' => { 'aaaa' => [{ 'ip' => '2001:db8::1', 'ttl' => 300 }] }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records).to eq([{ name: 'www', type: 'AAAA', data: '2001:db8::1', ttl: 300 }])
    end

    it 'parses SOA records from Redis' do
      redis_data = { '@' => { 'soa' => { 'ns' => 'ns01.example.com.', 'mbox' => 'admin.example.com.', 'refresh' => 3600, 'retry' => 600, 'expire' => 86400, 'minttl' => 300, 'ttl' => 3600 } }.to_json }
      allow(redis_mock).to receive(:hgetall).with('example.com.').and_return(redis_data)

      records = dns_zone.zone_records
      expect(records.length).to eq(1)
      expect(records.first[:type]).to eq('SOA')
      expect(records.first[:data]).to eq('ns01.example.com. admin.example.com. 3600 600 86400 300')
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

  describe '#prepare_aaaa' do
    let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }

    it 'returns nil when no AAAA records exist' do
      expect(dns_zone.prepare_aaaa('www')).to be_nil
    end

    it 'returns array of AAAA records with ip field' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::AAAA, name: 'www', data: '2001:db8::1', ttl: 300)

      result = dns_zone.prepare_aaaa('www')
      expect(result).to eq([{ ip: '2001:db8::1', ttl: 300 }])
    end
  end

  describe '#prepare_records with AAAA' do
    let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }

    it 'includes AAAA records in the response hash' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::AAAA, name: 'www', data: '2001:db8::1')

      result = dns_zone.prepare_records('www')
      expect(result[:aaaa]).to eq([{ ip: '2001:db8::1', ttl: 300 }])
    end
  end

  describe '#default_primary_ns' do
    it 'uses DEFAULT_PRIMARY_NS env var when set' do
      dns_zone = DnsZone.create!(name: 'sub.example.com', redis_host: 'localhost')
      allow(ENV).to receive(:fetch).with('DEFAULT_PRIMARY_NS', anything).and_return('ns01.example.com.')

      expect(dns_zone.send(:default_primary_ns)).to eq('ns01.example.com.')
    end

    it 'falls back to ns01.{name}. when env var is not set' do
      dns_zone = DnsZone.create!(name: 'test.example.com', redis_host: 'localhost')
      cached_val = ENV['DEFAULT_PRIMARY_NS']
      ENV.delete('DEFAULT_PRIMARY_NS')

      expect(dns_zone.send(:default_primary_ns)).to eq('ns01.test.example.com.')
    ensure
      ENV['DEFAULT_PRIMARY_NS'] = cached_val if cached_val
    end
  end
end
