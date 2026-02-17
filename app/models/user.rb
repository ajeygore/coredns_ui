class User < ApplicationRecord
  include ZoneAccessible

  has_many :api_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true

  def self.from_omniauth(auth) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # 1. Returning user — already has provider + uid
    existing = find_by(auth_provider: auth.provider, uid: auth.uid)
    return existing if existing

    # 2. Admin bootstrap via ADMIN_USER_EMAIL env var
    admin_email = ENV.fetch('ADMIN_USER_EMAIL', nil)
    if admin_email.present? && auth.info.email.casecmp(admin_email) == 0
      user = find_or_initialize_by(email: auth.info.email)
      user.assign_attributes(
        name: auth.info.name,
        auth_provider: auth.provider,
        uid: auth.uid,
        admin: true,
        permitted: true,
        permitted_zones: '*'
      )
      user.save!
      return user
    end

    # 3. Invited user — exists by email with permitted: true, first login
    invited = find_by(email: auth.info.email, permitted: true)
    if invited
      invited.update!(
        name: auth.info.name,
        auth_provider: auth.provider,
        uid: auth.uid
      )
      return invited
    end

    # 4. Not authorized
    nil
  end

  def accessible_zones
    return DnsZone.all if permitted_zones.blank? || permitted_zones.strip == '*'

    DnsZone.where(name: permitted_zone_list)
  end
end
