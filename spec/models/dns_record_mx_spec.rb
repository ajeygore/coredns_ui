require 'rails_helper'

RSpec.describe DnsRecord, type: :model do
  let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }
  let(:redis_mock) { instance_double(Redis) }

  before do
    allow(Redis).to receive(:new).and_return(redis_mock)
    allow(redis_mock).to receive(:hset)
  end

  describe 'MX record validation' do
    it 'accepts valid MX record format' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '10 mail.example.com', name: 'test')
      expect(record).to be_valid
    end

    it 'rejects MX record with missing priority' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: 'mail.example.com', name: 'test')
      expect(record).not_to be_valid
      expect(record.errors[:data]).to include('must be in format "priority hostname" (e.g., "10 mail.example.com")')
    end

    it 'rejects MX record with invalid priority' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: 'invalid mail.example.com',
                             name: 'test')
      expect(record).not_to be_valid
      expect(record.errors[:data]).to include('priority must be a number')
    end

    it 'rejects MX record with priority out of range' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '65536 mail.example.com',
                             name: 'test')
      expect(record).not_to be_valid
      expect(record.errors[:data]).to include('priority must be between 0 and 65535')
    end

    it 'rejects MX record with invalid hostname characters' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '10 mail@example.com', name: 'test')
      expect(record).not_to be_valid
      expect(record.errors[:data]).to include('hostname contains invalid characters')
    end

    it 'rejects MX record with hostname too long' do
      long_hostname = 'a' * 256
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: "10 #{long_hostname}", name: 'test')
      expect(record).not_to be_valid
      expect(record.errors[:data]).to include('hostname is too long (maximum 255 characters)')
    end

    it 'accepts MX record with priority 0' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '0 mail.example.com', name: 'test')
      expect(record).to be_valid
    end

    it 'accepts MX record with priority 65535' do
      record = DnsRecord.new(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '65535 mail.example.com',
                             name: 'test')
      expect(record).to be_valid
    end
  end

  describe '#add_mx' do
    let(:mx_record) { DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '10 mail.example.com', name: 'test') }

    it 'creates correct Redis entry for MX record' do
      expected_record = { mx: [{ priority: 10, host: 'mail.example.com', ttl: 300 }] }
      expect(redis_mock).to receive(:hset).with("#{dns_zone.name}.", 'test', expected_record.to_json)

      mx_record.add_mx
    end

    it 'handles zone name without trailing dot' do
      dns_zone.update(name: 'example.com')
      expected_record = { mx: [{ priority: 10, host: 'mail.example.com', ttl: 300 }] }
      expect(redis_mock).to receive(:hset).with('example.com.', 'test', expected_record.to_json)

      mx_record.add_mx
    end

    it 'handles zone name with trailing dot' do
      dns_zone.update(name: 'example.com.')
      expected_record = { mx: [{ priority: 10, host: 'mail.example.com', ttl: 300 }] }
      expect(redis_mock).to receive(:hset).with('example.com.', 'test', expected_record.to_json)

      mx_record.add_mx
    end

    it 'uses correct TTL value' do
      mx_record.update(ttl: 600)
      expected_record = { mx: [{ priority: 10, host: 'mail.example.com', ttl: 600 }] }
      expect(redis_mock).to receive(:hset).with("#{dns_zone.name}.", 'test', expected_record.to_json)

      mx_record.add_mx
    end
  end

  describe '#update_redis' do
    it 'calls add_mx for MX record type' do
      mx_record = DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '10 mail.example.com',
                                    name: 'test')
      expect(mx_record).to receive(:add_mx)
      mx_record.update_redis
    end
  end

  describe '#mx_priority and #mx_host' do
    let(:mx_record) { DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::MX, data: '10 mail.example.com', name: 'test') }
    let(:non_mx_record) { DnsRecord.create!(dns_zone: dns_zone, record_type: DnsRecord::A, data: '1.2.3.4', name: 'test') }

    it 'returns priority for MX record' do
      expect(mx_record.mx_priority).to eq(10)
    end

    it 'returns host for MX record' do
      expect(mx_record.mx_host).to eq('mail.example.com')
    end

    it 'returns nil for non-MX record priority' do
      expect(non_mx_record.mx_priority).to be_nil
    end

    it 'returns nil for non-MX record host' do
      expect(non_mx_record.mx_host).to be_nil
    end
  end
end
