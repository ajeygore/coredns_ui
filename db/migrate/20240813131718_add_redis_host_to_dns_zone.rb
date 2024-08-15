class AddRedisHostToDnsZone < ActiveRecord::Migration[7.2]
  def change
    add_column :dns_zones, :redis_host, :string
  end
end
