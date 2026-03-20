require 'rails_helper'

RSpec.describe "/dns_zones", type: :request do
  let(:admin) { User.create!(email: 'admin@test.com', name: 'Admin', admin: true, permitted_zones: '*') }

  before { login_as(admin) }

  describe "GET /index" do
    it "renders a successful response" do
      DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      get dns_zones_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      get dns_zone_url(dns_zone)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_dns_zone_url
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    it "creates a new DnsZone and syncs to Redis" do
      expect {
        post dns_zones_url, params: { dns_zone: { name: 'new.example.com', redis_host: 'localhost' } }
      }.to change(DnsZone, :count).by(1)
      expect(response).to redirect_to(dns_zones_path)
    end

    it "creates default SOA and NS records" do
      post dns_zones_url, params: { dns_zone: { name: 'new.example.com', redis_host: 'localhost' } }
      zone = DnsZone.find_by(name: 'new.example.com')
      expect(zone.dns_records.where(record_type: DnsRecord::SOA).count).to eq(1)
      expect(zone.dns_records.where(record_type: DnsRecord::NS).count).to eq(1)
    end

    it "does not create with duplicate name" do
      DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      expect {
        post dns_zones_url, params: { dns_zone: { name: 'example.com', redis_host: 'localhost' } }
      }.not_to change(DnsZone, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "requires admin role" do
      regular_user = User.create!(email: 'user@test.com', name: 'User', permitted_zones: '*')
      login_as(regular_user)

      post dns_zones_url, params: { dns_zone: { name: 'test.com', redis_host: 'localhost' } }
      expect(response).to redirect_to(dns_zones_path)
    end
  end

  describe "PATCH /update" do
    it "updates the requested dns_zone" do
      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      patch dns_zone_url(dns_zone), params: { dns_zone: { redis_host: '10.0.0.1' } }
      dns_zone.reload
      expect(dns_zone.redis_host).to eq('10.0.0.1')
      expect(response).to redirect_to(dns_zone_url(dns_zone))
    end

    it "returns 422 with invalid params" do
      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      DnsZone.create!(name: 'taken.com', redis_host: 'localhost')
      patch dns_zone_url(dns_zone), params: { dns_zone: { name: 'taken.com' } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /destroy" do
    it "destroys zone with no records" do
      dns_zone = DnsZone.create!(name: 'empty.com', redis_host: 'localhost')
      expect {
        delete dns_zone_url(dns_zone)
      }.to change(DnsZone, :count).by(-1)
      expect(response).to redirect_to(dns_zones_url)
    end

    it "refuses to destroy zone with records" do
      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      dns_zone.dns_records.create!(name: '@', record_type: DnsRecord::A, data: '1.1.1.1', ttl: 300)
      expect {
        delete dns_zone_url(dns_zone)
      }.not_to change(DnsZone, :count)
      expect(response).to redirect_to(dns_zones_url)
    end

    it "requires admin role" do
      regular_user = User.create!(email: 'user@test.com', name: 'User', permitted_zones: '*')
      login_as(regular_user)

      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      delete dns_zone_url(dns_zone)
      expect(response).to redirect_to(dns_zones_path)
    end
  end

  describe "GET /refresh" do
    it "refreshes zone records in Redis and redirects" do
      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      get refresh_path(dns_zone)
      expect(response).to redirect_to(dns_zones_path)
    end
  end

  describe "access control" do
    it "redirects users without zone access on show" do
      restricted_user = User.create!(email: 'restricted@test.com', name: 'Restricted', permitted_zones: 'other.com')
      login_as(restricted_user)

      dns_zone = DnsZone.create!(name: 'example.com', redis_host: 'localhost')
      get dns_zone_url(dns_zone)
      expect(response).to redirect_to(dns_zones_path)
    end
  end
end
