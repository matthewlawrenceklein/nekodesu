class DropRenshuuSchedules < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :renshuu_items, :renshuu_schedules if foreign_key_exists?(:renshuu_items, :renshuu_schedules)
    drop_table :renshuu_schedules
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
