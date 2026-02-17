class ApiToken < ApplicationRecord
  include ZoneAccessible

  belongs_to :user, optional: true

  before_create :generate_token

  validates :token, presence: true, uniqueness: true

  def generate_token
    self.token = SecureRandom.hex(20) # Generates a random 40-character hexadecimal string
  end
end
