class CreateDialogueAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :dialogue_attempts do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :dialogue, null: false, foreign_key: true, index: true
      t.jsonb :answers, default: {}, null: false
      t.integer :correct_count, default: 0
      t.integer :total_questions, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    add_index :dialogue_attempts, [ :user_id, :dialogue_id ]
    add_index :dialogue_attempts, :completed_at
  end
end
