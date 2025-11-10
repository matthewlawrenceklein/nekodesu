class CreateRenshuuSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :renshuu_schedules do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :external_id
      t.string :name
      t.string :schedule_type
      t.integer :item_count
      t.datetime :last_synced_at

      t.timestamps
    end
  end
end
