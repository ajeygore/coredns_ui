class ServerSetting < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  KEYS = %w[
    default_primary_ns
    default_admin_email
    default_redis_host
    soa_refresh
    soa_retry
    soa_expire
    soa_minttl
  ].freeze

  def self.get(key)
    find_by(key: key)&.value
  end

  def self.set(key, value)
    setting = find_or_initialize_by(key: key)
    setting.update!(value: value)
  end

  def self.default_primary_ns
    get('default_primary_ns') || ENV.fetch('DEFAULT_PRIMARY_NS', nil)
  end

  def self.default_admin_email
    get('default_admin_email')
  end

  def self.default_redis_host
    get('default_redis_host') || ENV.fetch('REDIS_HOST', 'localhost')
  end

  def self.soa_timing
    refresh = get('soa_refresh') || '3600'
    retries = get('soa_retry') || '600'
    expire = get('soa_expire') || '86400'
    minttl = get('soa_minttl') || '300'
    "#{refresh} #{retries} #{expire} #{minttl}"
  end
end
