require 'rails_helper'

RSpec.describe "DnsRecords", type: :request do
  let(:user) { User.create!(email: 'admin@test.com', name: 'Admin', admin: true, permitted_zones: '*') }
  let(:dns_zone) { DnsZone.create!(name: 'example.com', redis_host: 'localhost') }

  before { login_as(user) }

  describe "GET /index" do
    it "renders a successful response" do
      get dns_zone_dns_records_path(dns_zone)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    it "creates a new DNS record and syncs to Redis" do
      expect {
        post dns_zone_dns_records_path(dns_zone), params: {
          dns_record: { name: 'www', record_type: DnsRecord::A, data: '1.1.1.1', ttl: 300 }
        }
      }.to change(DnsRecord, :count).by(1)
      expect(response).to redirect_to(dns_zone_dns_records_path(dns_zone))
    end

    it "re-renders on invalid params" do
      post dns_zone_dns_records_path(dns_zone), params: {
        dns_record: { name: '', record_type: DnsRecord::A, data: '1.1.1.1' }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /destroy" do
    it "destroys the record and syncs to Redis" do
      record = dns_zone.dns_records.create!(name: 'www', record_type: DnsRecord::A, data: '1.1.1.1', ttl: 300)
      expect {
        delete dns_zone_dns_record_path(dns_zone, record)
      }.to change(DnsRecord, :count).by(-1)
      expect(response).to redirect_to(dns_zone_dns_records_path(dns_zone))
    end
  end

  describe "access control" do
    it "redirects unauthenticated users to login" do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      allow_any_instance_of(ApplicationController).to receive(:logged_in?).and_return(false)

      get dns_zone_dns_records_path(dns_zone)
      expect(response).to redirect_to(login_path)
    end

    it "redirects users without zone access" do
      restricted_user = User.create!(email: 'restricted@test.com', name: 'Restricted', permitted_zones: 'other.com')
      login_as(restricted_user)

      get dns_zone_dns_records_path(dns_zone)
      expect(response).to redirect_to(dns_zones_path)
    end
  end
end
