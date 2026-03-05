class CreateServerSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :server_settings do |t|
      t.string :key, null: false, index: { unique: true }
      t.string :value

      t.timestamps
    end
  end
end
