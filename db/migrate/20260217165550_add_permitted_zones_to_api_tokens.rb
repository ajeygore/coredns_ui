class AddPermittedZonesToApiTokens < ActiveRecord::Migration[8.0]
  def change
    add_column :api_tokens, :permitted_zones, :string, default: '*'
  end
end
