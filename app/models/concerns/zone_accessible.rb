module ZoneAccessible
  extend ActiveSupport::Concern

  def can_access_zone?(zone)
    can_access_zone_name?(zone.name)
  end

  def can_access_zone_name?(name)
    return true if permitted_zones.blank? || permitted_zones.strip == '*'

    permitted_zone_list.any? { |z| z.casecmp(name) == 0 }
  end

  def permitted_zone_list
    return [] if permitted_zones.blank? || permitted_zones.strip == '*'

    permitted_zones.split(',').map(&:strip)
  end
end
