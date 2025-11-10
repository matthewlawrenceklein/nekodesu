class MakeRenshuuScheduleIdNullableInRenshuuItems < ActiveRecord::Migration[8.1]
  def change
    change_column_null :renshuu_items, :renshuu_schedule_id, true
  end
end
