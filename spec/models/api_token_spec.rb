require 'rails_helper'

RSpec.describe ApiToken, type: :model do
  let(:user) { User.create!(email: 'test@example.com', name: 'Test') }

  it 'auto-generates a token on create' do
    token = ApiToken.create!(user: user)
    expect(token.token).to be_present
    expect(token.token.length).to eq(40)
  end

  it 'validates uniqueness of token' do
    token1 = ApiToken.create!(user: user)
    # Create second token then manually set duplicate token, skipping generate callback
    token2 = ApiToken.create!(user: user)
    token2.token = token1.token
    expect(token2).not_to be_valid
    expect(token2.errors[:token]).to include('has already been taken')
  end

  it 'validates presence of token' do
    token = ApiToken.new(user: user, token: nil)
    # before_validation generates token, so we need to skip that
    token.instance_variable_set(:@_skip_generate, true)
    allow(token).to receive(:generate_token)
    expect(token).not_to be_valid
  end

  describe 'zone access (ZoneAccessible)' do
    it 'grants access to all zones when permitted_zones is *' do
      token = ApiToken.create!(user: user, permitted_zones: '*')
      zone = DnsZone.create!(name: 'example.com')
      expect(token.can_access_zone?(zone)).to be true
    end

    it 'grants access to specific permitted zones' do
      token = ApiToken.create!(user: user, permitted_zones: 'example.com, test.com')
      zone = DnsZone.create!(name: 'example.com')
      expect(token.can_access_zone?(zone)).to be true
    end

    it 'denies access to non-permitted zones' do
      token = ApiToken.create!(user: user, permitted_zones: 'other.com')
      zone = DnsZone.create!(name: 'example.com')
      expect(token.can_access_zone?(zone)).to be false
    end
  end
end
