class MarkExistingUsersAsPermitted < ActiveRecord::Migration[8.0]
  def up
    User.update_all(permitted: true)
  end

  def down
    User.update_all(permitted: false)
  end
end
