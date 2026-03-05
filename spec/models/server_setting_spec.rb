require 'rails_helper'

RSpec.describe ServerSetting, type: :model do
  describe 'validations' do
    it 'requires a key' do
      setting = ServerSetting.new(value: 'test')
      expect(setting).not_to be_valid
      expect(setting.errors[:key]).to include("can't be blank")
    end

    it 'requires unique keys' do
      ServerSetting.create!(key: 'test_key', value: 'val1')
      dup = ServerSetting.new(key: 'test_key', value: 'val2')
      expect(dup).not_to be_valid
    end
  end

  describe '.get and .set' do
    it 'returns nil for missing keys' do
      expect(ServerSetting.get('nonexistent')).to be_nil
    end

    it 'stores and retrieves a value' do
      ServerSetting.set('test_key', 'hello')
      expect(ServerSetting.get('test_key')).to eq('hello')
    end

    it 'updates an existing value' do
      ServerSetting.set('test_key', 'first')
      ServerSetting.set('test_key', 'second')
      expect(ServerSetting.get('test_key')).to eq('second')
      expect(ServerSetting.where(key: 'test_key').count).to eq(1)
    end
  end

  describe '.default_primary_ns' do
    it 'returns DB value when set' do
      ServerSetting.set('default_primary_ns', 'ns01.example.com.')
      expect(ServerSetting.default_primary_ns).to eq('ns01.example.com.')
    end

    it 'falls back to ENV var' do
      allow(ENV).to receive(:fetch).with('DEFAULT_PRIMARY_NS', nil).and_return('ns01.env.com.')
      expect(ServerSetting.default_primary_ns).to eq('ns01.env.com.')
    end

    it 'returns nil when neither DB nor ENV is set' do
      allow(ENV).to receive(:fetch).with('DEFAULT_PRIMARY_NS', nil).and_return(nil)
      expect(ServerSetting.default_primary_ns).to be_nil
    end
  end

  describe '.default_admin_email' do
    it 'returns DB value when set' do
      ServerSetting.set('default_admin_email', 'admin.example.com.')
      expect(ServerSetting.default_admin_email).to eq('admin.example.com.')
    end

    it 'returns nil when not set' do
      expect(ServerSetting.default_admin_email).to be_nil
    end
  end

  describe '.default_redis_host' do
    it 'returns DB value when set' do
      ServerSetting.set('default_redis_host', '10.0.0.1')
      expect(ServerSetting.default_redis_host).to eq('10.0.0.1')
    end

    it 'falls back to ENV var' do
      allow(ENV).to receive(:fetch).with('REDIS_HOST', 'localhost').and_return('redis.local')
      expect(ServerSetting.default_redis_host).to eq('redis.local')
    end
  end

  describe '.soa_timing' do
    it 'returns defaults when nothing is configured' do
      expect(ServerSetting.soa_timing).to eq('3600 600 86400 300')
    end

    it 'uses configured values' do
      ServerSetting.set('soa_refresh', '7200')
      ServerSetting.set('soa_retry', '1200')
      ServerSetting.set('soa_expire', '172800')
      ServerSetting.set('soa_minttl', '600')
      expect(ServerSetting.soa_timing).to eq('7200 1200 172800 600')
    end
  end
end
