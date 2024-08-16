class AddUidToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :uid, :string
  end
end
