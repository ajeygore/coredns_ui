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
    expect(prepared_cname).to eq("canonical.example.com")
    
    # Test the complete record structure
    prepared_records = dns_zone.prepare_records('alias')
    expect(prepared_records).to eq({ cname: { host: "canonical.example.com", ttl: 300 } })
  end

  describe "CNAME record end-to-end flow" do
    let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }
    
    it "handles complete CNAME lifecycle from creation to retrieval" do
      # Step 1: Create a CNAME record
      cname_record = dns_zone.dns_records.create!(
        name: 'cdn', 
        record_type: DnsRecord::CNAME, 
        data: "cdn.vercel-dns.com."
      )
      
      # Verify record creation
      expect(dns_zone.dns_records.where(record_type: DnsRecord::CNAME).count).to eq(1)
      expect(cname_record.name).to eq('cdn')
      expect(cname_record.data).to eq('cdn.vercel-dns.com.')
      expect(cname_record.time_to_live).to eq(300) # default TTL
      
      # Step 2: Test individual prepare_cname method
      cname_data = dns_zone.prepare_cname('cdn')
      expect(cname_data).to eq('cdn.vercel-dns.com.')
      
      # Step 3: Test prepare_records method (full structure)
      records = dns_zone.prepare_records('cdn')
      expect(records).to eq({
        cname: { host: 'cdn.vercel-dns.com.', ttl: 300 }
      })
      
      # Step 4: Test that non-existent records return nil
      expect(dns_zone.prepare_cname('nonexistent')).to be_nil
      expect(dns_zone.prepare_records('nonexistent')).to eq({})
      
      # Step 5: Test with custom TTL
      custom_cname = dns_zone.dns_records.create!(
        name: 'custom',
        record_type: DnsRecord::CNAME,
        data: "custom.example.com.",
        ttl: 600
      )
      
      custom_records = dns_zone.prepare_records('custom')
      expect(custom_records).to eq({
        cname: { host: 'custom.example.com.', ttl: 600 }
      })
      
      # Step 6: Test that prepare_cname returns the first CNAME when multiple exist
      # (Note: While DNS standards suggest one CNAME per name, the current validation 
      # allows multiple with different data)
      dns_zone.dns_records.create!(
        name: 'cdn',
        record_type: DnsRecord::CNAME,
        data: "another.example.com."
      )
      
      # Should still return the first one found
      expect(dns_zone.prepare_cname('cdn')).to eq('cdn.vercel-dns.com.')
    end
    
    it "ensures CNAME records work correctly with zone refresh" do
      # Create CNAME record
      dns_zone.dns_records.create!(
        name: 'api',
        record_type: DnsRecord::CNAME,
        data: "api.vercel-dns.com.",
        ttl: 600
      )
      
      # Mock Redis to test the refresh functionality
      redis_mock = instance_double(Redis)
      allow(Redis).to receive(:new).with(host: 'localhost').and_return(redis_mock)
      
      # Expect Redis operations during refresh
      expect(redis_mock).to receive(:del).with('example.com.')
      expect(redis_mock).to receive(:hset).with(
        'example.com.',
        'api',
        { cname: { host: 'api.vercel-dns.com.', ttl: 600 } }.to_json
      )
      
      # Trigger refresh
      dns_zone.refresh
    end
    
    it "handles CNAME mixed with other record types correctly" do
      # Create CNAME record
      dns_zone.dns_records.create!(
        name: 'blog',
        record_type: DnsRecord::CNAME,
        data: "blog.github.io."
      )
      
      # Create A record for different subdomain
      dns_zone.dns_records.create!(
        name: 'www',
        record_type: DnsRecord::A,
        data: "192.168.1.1"
      )
      
      # Test CNAME retrieval
      blog_records = dns_zone.prepare_records('blog')
      expect(blog_records).to eq({
        cname: { host: 'blog.github.io.', ttl: 300 }
      })
      
      # Test A record retrieval
      www_records = dns_zone.prepare_records('www')
      expect(www_records).to eq({
        a: [{ ip: '192.168.1.1', ttl: 300 }]
      })
      
      # Ensure they don't interfere with each other
      expect(dns_zone.dns_records.count).to eq(2)
    end
  end
end
