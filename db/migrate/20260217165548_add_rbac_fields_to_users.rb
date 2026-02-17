class AddRbacFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :permitted_zones, :string, default: '*'
    add_column :users, :permitted, :boolean, default: false
  end
end
