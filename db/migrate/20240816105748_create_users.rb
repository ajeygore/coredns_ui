class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :name
      t.string :alias_name
      t.string :email
      t.string :profile_photopath
      t.string :auth_provider
      t.boolean :admin

      t.timestamps
    end
  end
end
