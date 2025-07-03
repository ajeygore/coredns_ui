require 'rails_helper'
require 'resolv'

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

  it "creates and processes a CNAME record correctly with array format" do
    dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
    cname_record = dns_zone.dns_records.create!(name: 'alias', record_type: DnsRecord::CNAME, data: "canonical.example.com")
    
    # Check that the record is valid and exists
    expect(dns_zone.dns_records.count).to eq(1)
    expect(cname_record.record_type).to eq("CNAME")
    
    # Test the helper method from the zone
    prepared_cname = dns_zone.prepare_cname('alias')
    expect(prepared_cname).to eq("canonical.example.com")
    
    # Test the complete record structure (MUST be array format for CoreDNS)
    prepared_records = dns_zone.prepare_records('alias')
    expect(prepared_records).to eq({ cname: [{ host: "canonical.example.com", ttl: 300 }] })
    
    # Test JSON serialization matches CoreDNS expected format
    json_output = prepared_records.to_json
    parsed_json = JSON.parse(json_output)
    expect(parsed_json["cname"]).to be_a(Array)
    expect(parsed_json["cname"].first["host"]).to eq("canonical.example.com")
    expect(parsed_json["cname"].first["ttl"]).to eq(300)
  end

  describe "CNAME record end-to-end flow" do
    let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }
    
    it "handles complete CNAME lifecycle from creation to retrieval" do
      # Mock DNS resolution
      allow(Resolv).to receive(:getaddress).with('cdn.vercel-dns.com.').and_return('76.76.21.21')
      
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
      
      # Step 3: Test prepare_records method (full structure - array format for CoreDNS)
      records = dns_zone.prepare_records('cdn')
      expect(records).to eq({
        cname: [{ host: 'cdn.vercel-dns.com.', ttl: 300 }],
        a: [{ ip: '76.76.21.21', ttl: 300 }]
      })
      
      # Step 4: Test that non-existent records return nil
      expect(dns_zone.prepare_cname('nonexistent')).to be_nil
      expect(dns_zone.prepare_records('nonexistent')).to eq({})
      
      # Step 5: Test with custom TTL
      allow(Resolv).to receive(:getaddress).with('custom.example.com.').and_return('192.168.1.1')
      
      custom_cname = dns_zone.dns_records.create!(
        name: 'custom',
        record_type: DnsRecord::CNAME,
        data: "custom.example.com.",
        ttl: 600
      )
      
      custom_records = dns_zone.prepare_records('custom')
      expect(custom_records).to eq({
        cname: [{ host: 'custom.example.com.', ttl: 600 }],
        a: [{ ip: '192.168.1.1', ttl: 600 }]
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
      # Mock DNS resolution
      allow(Resolv).to receive(:getaddress).with('api.vercel-dns.com.').and_return('1.2.3.4')
      
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
      
      # Expect Redis operations during refresh (array format)
      expect(redis_mock).to receive(:del).with('example.com.')
      expect(redis_mock).to receive(:hset).with(
        'example.com.',
        'api',
        { cname: [{ host: 'api.vercel-dns.com.', ttl: 600 }], a: [{ ip: '1.2.3.4', ttl: 600 }] }.to_json
      )
      
      # Trigger refresh
      dns_zone.refresh
    end
    
    it "handles CNAME mixed with other record types correctly" do
      # Mock DNS resolution
      allow(Resolv).to receive(:getaddress).with('blog.github.io.').and_return('5.6.7.8')
      
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
      
      # Test CNAME retrieval (array format)
      blog_records = dns_zone.prepare_records('blog')
      expect(blog_records).to eq({
        cname: [{ host: 'blog.github.io.', ttl: 300 }],
        a: [{ ip: '5.6.7.8', ttl: 300 }]
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

  describe "CoreDNS compatibility tests" do
    let(:dns_zone) { DnsZone.create!(name: 'soranova.ai', redis_host: 'localhost') }

    it "generates CNAME records in the exact format that CoreDNS expects" do
      # Mock DNS resolution
      allow(Resolv).to receive(:getaddress).with('cname.vercel-dns.com.').and_return('76.76.21.21')
      
      # Create a CNAME record like the docs.soranova.ai example
      cname_record = dns_zone.dns_records.create!(
        name: 'docs',
        record_type: DnsRecord::CNAME,
        data: 'cname.vercel-dns.com.',
        ttl: 300
      )

      # Test the prepared records format
      records = dns_zone.prepare_records('docs')
      expected_format = {
        cname: [{ host: 'cname.vercel-dns.com.', ttl: 300 }],
        a: [{ ip: '76.76.21.21', ttl: 300 }]
      }
      expect(records).to eq(expected_format)

      # Test JSON serialization matches what we store in Redis
      json_string = records.to_json
      expect(json_string).to eq('{"cname":[{"host":"cname.vercel-dns.com.","ttl":300}],"a":[{"ip":"76.76.21.21","ttl":300}]}')

      # Test that parsing this JSON back gives us the expected structure
      parsed = JSON.parse(json_string)
      expect(parsed['cname']).to be_a(Array)
      expect(parsed['cname'].length).to eq(1)
      expect(parsed['cname'].first['host']).to eq('cname.vercel-dns.com.')
      expect(parsed['cname'].first['ttl']).to eq(300)
    end

    it "validates CNAME array format prevents CoreDNS parse errors" do
      dns_zone.dns_records.create!(
        name: 'api',
        record_type: DnsRecord::CNAME,
        data: 'api.example.com.'
      )

      records = dns_zone.prepare_records('api')
      
      # Ensure cname is always an array, never a single object
      expect(records[:cname]).to be_a(Array)
      expect(records[:cname]).not_to be_a(Hash)
      
      # Verify the structure matches CoreDNS Redis plugin expectations
      cname_entry = records[:cname].first
      expect(cname_entry).to have_key(:host)
      expect(cname_entry).to have_key(:ttl)
      expect(cname_entry[:host]).to be_a(String)
      expect(cname_entry[:ttl]).to be_a(Integer)
    end

    it "handles multiple CNAME records correctly (though DNS-wise only first should be used)" do
      # Create multiple CNAME records for the same name (edge case)
      dns_zone.dns_records.create!(
        name: 'multi',
        record_type: DnsRecord::CNAME,
        data: 'first.example.com.'
      )
      dns_zone.dns_records.create!(
        name: 'multi',
        record_type: DnsRecord::CNAME,
        data: 'second.example.com.'
      )

      # prepare_cname should return the first one found
      cname_data = dns_zone.prepare_cname('multi')
      expect(cname_data).to eq('first.example.com.')

      # But the record structure should still be in array format
      records = dns_zone.prepare_records('multi')
      expect(records[:cname]).to be_a(Array)
      expect(records[:cname].first[:host]).to eq('first.example.com.')
    end

    it "compares A record vs CNAME record format consistency" do
      # Create both A and CNAME records
      dns_zone.dns_records.create!(name: 'www', record_type: DnsRecord::A, data: '1.1.1.1')
      dns_zone.dns_records.create!(name: 'cdn', record_type: DnsRecord::CNAME, data: 'cdn.example.com.')

      a_records = dns_zone.prepare_records('www')
      cname_records = dns_zone.prepare_records('cdn')

      # Both should use array format for consistency
      expect(a_records[:a]).to be_a(Array)
      expect(cname_records[:cname]).to be_a(Array)

      # Verify structure similarity
      expect(a_records[:a].first).to have_key(:ttl)
      expect(cname_records[:cname].first).to have_key(:ttl)
    end

    it "simulates the exact Redis storage and retrieval that fixed the CoreDNS issue" do
      # Mock DNS resolution
      allow(Resolv).to receive(:getaddress).with('cname.vercel-dns.com.').and_return('76.76.21.21')
      
      # This test replicates the exact scenario that was failing
      dns_zone.dns_records.create!(
        name: 'docs',
        record_type: DnsRecord::CNAME,
        data: 'cname.vercel-dns.com.',
        ttl: 300
      )

      # Mock Redis to capture what gets stored
      redis_mock = instance_double(Redis)
      allow(Redis).to receive(:new).and_return(redis_mock)
      expect(redis_mock).to receive(:del).with('soranova.ai.')
      
      # This is the exact format that CoreDNS now accepts (array format) with resolved A record
      expected_redis_value = '{"cname":[{"host":"cname.vercel-dns.com.","ttl":300}],"a":[{"ip":"76.76.21.21","ttl":300}]}'
      expect(redis_mock).to receive(:hset).with('soranova.ai.', 'docs', expected_redis_value)

      # Trigger the refresh that stores to Redis
      dns_zone.refresh

      # Verify that if we parse this back, it has the correct structure
      parsed = JSON.parse(expected_redis_value)
      expect(parsed['cname']).to be_a(Array)
      expect(parsed['a']).to be_a(Array)
      
      # This format should NOT cause the CoreDNS error:
      # "json: cannot unmarshal object into Go struct field Record.cname of type []redis.CNAME_Record"
    end
  end
end
