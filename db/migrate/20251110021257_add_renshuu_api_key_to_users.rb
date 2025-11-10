class AddRenshuuApiKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :renshuu_api_key, :string
    add_column :users, :last_renshuu_sync, :datetime
  end
end
