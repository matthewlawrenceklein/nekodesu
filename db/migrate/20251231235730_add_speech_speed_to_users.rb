class AddSpeechSpeedToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :speech_speed, :decimal, precision: 3, scale: 2, default: 1.0
  end
end
