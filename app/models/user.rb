class User < ApplicationRecord
  def self.from_omniauth(auth) # rubocop:disable Metrics/AbcSize
    where(auth_provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.auth_provider = auth.provider
      user.uid = auth.uid
      user.admin = User.all.count == 0
    end
  end
end
