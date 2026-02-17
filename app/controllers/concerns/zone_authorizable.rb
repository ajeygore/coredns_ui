module ZoneAuthorizable
  extend ActiveSupport::Concern

  private

  def authorize_zone_access!
    return if current_user.can_access_zone?(@dns_zone)

    redirect_to dns_zones_path, alert: 'You do not have access to this zone.'
  end
end
