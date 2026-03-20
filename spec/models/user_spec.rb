require 'rails_helper'

RSpec.describe User, type: :model do
  it 'validates presence of email' do
    user = User.new(name: 'Test')
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
  end

  it 'validates uniqueness of email' do
    User.create!(email: 'test@example.com', name: 'Test')
    user = User.new(email: 'test@example.com', name: 'Test2')
    expect(user).not_to be_valid
    expect(user.errors[:email]).to include('has already been taken')
  end

  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '12345',
        info: { email: 'user@example.com', name: 'Test User' }
      )
    end

    it 'returns existing user by provider and uid' do
      existing = User.create!(email: 'user@example.com', name: 'Test User',
                              auth_provider: 'google_oauth2', uid: '12345', permitted: true)
      expect(User.from_omniauth(auth)).to eq(existing)
    end

    it 'bootstraps admin user from ADMIN_USER_EMAIL env var' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ADMIN_USER_EMAIL', nil).and_return('user@example.com')

      user = User.from_omniauth(auth)
      expect(user).to be_persisted
      expect(user.admin).to be true
      expect(user.permitted_zones).to eq('*')
    end

    it 'allows invited user to log in' do
      User.create!(email: 'user@example.com', name: 'Invited', permitted: true)
      user = User.from_omniauth(auth)
      expect(user).to be_persisted
      expect(user.uid).to eq('12345')
    end

    it 'returns nil for unauthorized user' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('ADMIN_USER_EMAIL', nil).and_return(nil)
      expect(User.from_omniauth(auth)).to be_nil
    end
  end

  describe '#accessible_zones' do
    it 'returns all zones when permitted_zones is *' do
      user = User.create!(email: 'admin@test.com', name: 'Admin', permitted_zones: '*')
      DnsZone.create!(name: 'example.com')
      DnsZone.create!(name: 'test.com')
      expect(user.accessible_zones.count).to eq(2)
    end

    it 'returns only permitted zones' do
      user = User.create!(email: 'user@test.com', name: 'User', permitted_zones: 'example.com')
      DnsZone.create!(name: 'example.com')
      DnsZone.create!(name: 'test.com')
      expect(user.accessible_zones.count).to eq(1)
      expect(user.accessible_zones.first.name).to eq('example.com')
    end
  end
end
