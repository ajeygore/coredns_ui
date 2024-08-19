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

  context 'with valid api_token' do
    it 'creates a new subdomain and returns a success status' do
      post '/api/v1/zones/create_subdomain',
           params: @subdomain_params.to_json,
           headers: {
             'Authorization' => @api_token.token,
             'Content-Type' => 'application/json'
           }

      expect(response).to have_http_status(:created)
      expect(DnsZone.exists?(name: 'sub.example.com')).to be_truthy
      expect(DnsZone.find_by(name: 'sub.example.com').dns_records.count).to eq(2)
      expect(DnsZone.find_by(name: 'sub.example.com').dns_records.pluck(:record_type)).to match_array(%w[A A])
      expect(DnsZone.find_by(name: 'sub.example.com').dns_records.pluck(:name)).to match_array(%w[* @])
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
      expect(DnsZone.find_by(name: 'sub.example.com').dns_records.count).to eq(3)
      expect(DnsZone.find_by(name: 'sub.example.com').dns_records.pluck(:record_type)).to match_array(%w[A A TXT])
    end
  end
end
