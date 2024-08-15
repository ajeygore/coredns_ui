class CreateDnsRecords < ActiveRecord::Migration[7.2]
  def change
    create_table :dns_records do |t|
      t.string :record_type
      t.string :name
      t.string :data
      t.string :ttl
      t.references :dns_zone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
