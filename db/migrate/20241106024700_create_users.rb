class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :wanikani_api_key
      t.datetime :last_wanikani_sync

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
