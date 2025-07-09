require 'rails_helper'

RSpec.describe DnsZone, type: :model do
  let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }

  describe '#prepare_mx' do
    it 'returns nil when no MX records exist' do
      result = dns_zone.prepare_mx('test')
      expect(result).to be_nil
    end

    it 'returns array of MX records for given record name' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test', data: '10 mail1.example.com',
                        ttl: 300)
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test', data: '20 mail2.example.com',
                        ttl: 600)

      result = dns_zone.prepare_mx('test')

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result).to include({ priority: 10, host: 'mail1.example.com', ttl: 300 })
      expect(result).to include({ priority: 20, host: 'mail2.example.com', ttl: 600 })
    end

    it 'ignores MX records with different names' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test', data: '10 mail1.example.com')
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'other', data: '20 mail2.example.com')

      result = dns_zone.prepare_mx('test')

      expect(result.length).to eq(1)
      expect(result.first[:host]).to eq('mail1.example.com')
    end

    it 'correctly parses priority and hostname' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test',
                        data: '5 mail.subdomain.example.com', ttl: 120)

      result = dns_zone.prepare_mx('test')

      expect(result.first[:priority]).to eq(5)
      expect(result.first[:host]).to eq('mail.subdomain.example.com')
      expect(result.first[:ttl]).to eq(120)
    end
  end

  describe '#prepare_records' do
    it 'includes MX records in the response hash' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test', data: '10 mail.example.com')
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::A, name: 'test', data: '1.2.3.4')

      result = dns_zone.prepare_records('test')

      expect(result[:mx]).to be_present
      expect(result[:mx].first[:priority]).to eq(10)
      expect(result[:mx].first[:host]).to eq('mail.example.com')
      expect(result[:a]).to be_present
    end

    it 'excludes MX from response when no MX records exist' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::A, name: 'test', data: '1.2.3.4')

      result = dns_zone.prepare_records('test')

      expect(result[:mx]).to be_nil
      expect(result[:a]).to be_present
    end
  end

  describe '#refresh' do
    let(:redis_mock) { instance_double(Redis) }

    before do
      allow(Redis).to receive(:new).and_return(redis_mock)
      allow(redis_mock).to receive(:del)
      allow(redis_mock).to receive(:hset)
    end

    it 'includes MX records in Redis refresh' do
      DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, name: 'test', data: '10 mail.example.com')

      expected_json = { mx: [{ priority: 10, host: 'mail.example.com', ttl: 300 }] }.to_json
      expect(redis_mock).to receive(:hset).with("#{dns_zone.name}.", 'test', expected_json)

      dns_zone.refresh
    end
  end
end
