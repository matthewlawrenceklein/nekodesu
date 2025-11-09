class CreateDialogues < ActiveRecord::Migration[8.1]
  def change
    create_table :dialogues do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.text :japanese_text, null: false
      t.text :english_translation, null: false
      t.string :difficulty_level, null: false, index: true
      t.integer :min_level
      t.integer :max_level
      t.jsonb :vocabulary_used, default: []
      t.jsonb :kanji_used, default: []
      t.string :model_used
      t.integer :generation_time_ms

      t.timestamps
    end

    add_index :dialogues, :created_at
  end
end
