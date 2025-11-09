class AddOpenrouterApiKeyToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :openrouter_api_key, :string
  end
end
