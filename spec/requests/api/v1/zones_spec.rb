require 'rails_helper'

RSpec.describe 'Api::V1::Zones', type: :request do # rubocop:disable Metrics/BlockLength
  before do
    # Manually create the parent zone
    @user = User.create!(email: 'a@b.c', name: 'test', admin: true)
    @parent_zone = DnsZone.create!(name: "example.com")

    # Manually create the API token associated with the parent zone
    @api_token = ApiToken.create!(user: @user, token: SecureRandom.hex(20))

    # Define subdomain parameters
    @subdomain_params = { zone: { name: 'sub.example.com', data: '10.1.1.1' } }
  end

  context 'with invalid api_token' do
    it 'does not create a new subdomain and returns an unauthorized status' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => 'invalid_token',
             'Content-Type' => 'application/json'
           }

      expect(response).to have_http_status(:unauthorized)
      expect(DnsZone.exists?(name: 'sub.example.com')).to be_falsey
    end
  end

  context 'with valid api_token' do # rubocop:disable Metrics/BlockLength
    it 'creates a new subdomain and returns a success status' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      expect(response).to have_http_status(:created)
      expect(DnsZone.exists?(name: 'sub.example.com')).to be_truthy
      zone = DnsZone.find_by(name: 'sub.example.com')
      # ensure_default_records creates SOA + NS, then 2 A records (@ and *)
      expect(zone.dns_records.count).to eq(4)
      expect(zone.dns_records.pluck(:record_type)).to match_array(%w[SOA NS A A])
      expect(zone.dns_records.where(record_type: DnsRecord::A).pluck(:name)).to match_array(%w[* @])
    end

    it 'creates a new acme_challenge and returns a success status' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      @subdomain_params = { zone: { name: 'sub.example.com', data: '_acme' } }
      post '/api/v1/zones/create_acme_challenge',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      expect(response).to have_http_status(:created)
      expect(DnsZone.exists?(name: 'sub.example.com')).to be_truthy
      zone = DnsZone.find_by(name: 'sub.example.com')
      # SOA + NS + 2 A records + 1 TXT acme challenge
      expect(zone.dns_records.count).to eq(5)
      expect(zone.dns_records.pluck(:record_type)).to match_array(%w[SOA NS A A TXT])
    end

    it 'delete a new acme_challenge and returns a success status' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      @subdomain_params = { zone: { name: 'sub.example.com', data: '_acme' } }
      post '/api/v1/zones/create_acme_challenge',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      expect(response).to have_http_status(:created)
      expect(DnsZone.exists?(name: 'sub.example.com')).to be_truthy
      zone = DnsZone.find_by(name: 'sub.example.com')
      expect(zone.dns_records.count).to eq(5)
      expect(zone.dns_records.pluck(:record_type)).to match_array(%w[SOA NS A A TXT])

      delete '/api/v1/zones/delete_acme_challenge',
             params: @subdomain_params.to_json,
             headers: {
               'Authorization' => @api_token.token,
               'Content-Type' => 'application/json'
             }
      expect(zone.dns_records.count).to eq(4)
    end

    # Safety property (see #12): delete_subdomain MUST NOT destroy a zone. When
    # called without a :subdomain it returns 404 and leaves everything intact.
    # The old destructive behavior (this used to assert the whole zone was
    # gone) took clawstation.ai down twice — do not restore it.
    it 'does NOT destroy the zone when called without a :subdomain' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }
      expect(response).to have_http_status(:created)
      zone = DnsZone.find_by(name: 'sub.example.com')
      expect(zone.dns_records.count).to eq(4)

      delete '/api/v1/zones/delete_subdomain',
             params: @subdomain_params.to_json,
             headers: {
               'Authorization' => @api_token.token,
               'Content-Type' => 'application/json'
             }

      expect(response).to have_http_status(:not_found)
      expect(DnsZone.find_by(name: 'sub.example.com')).not_to be_nil
      expect(zone.reload.dns_records.count).to eq(4)
    end

    # Regression: delete_subdomain was 404'ing in production because :subdomain
    # was missing from the strong-params permit list, so the model never saw
    # it and returned false. Every DNS delete call was silently leaking the
    # leaf A record. See ClawStation #318.
    it 'should delete a single leaf record within an apex zone' do
      apex = DnsZone.find_by(name: 'example.com') || DnsZone.create!(name: 'example.com')
      apex.dns_records.create!(name: 'leaf-to-delete', record_type: DnsRecord::A, data: '10.0.0.1', ttl: '300')
      apex.dns_records.create!(name: 'leaf-to-keep',   record_type: DnsRecord::A, data: '10.0.0.2', ttl: '300')

      delete '/api/v1/zones/delete_subdomain',
             params: { zone: { name: 'example.com', subdomain: 'leaf-to-delete' } }.to_json,
             headers: {
               'Authorization' => @api_token.token,
               'Content-Type' => 'application/json'
             }

      expect(response).to have_http_status(:ok)
      expect(apex.dns_records.where(name: 'leaf-to-delete')).to be_empty
      expect(apex.dns_records.where(name: 'leaf-to-keep')).not_to be_empty
    end
  end
end
