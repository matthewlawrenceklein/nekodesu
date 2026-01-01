class CreateAnkiVocabs < ActiveRecord::Migration[8.1]
  def change
    create_table :anki_vocabs do |t|
      t.references :user, null: false, foreign_key: true
      t.string :term
      t.string :reading
      t.jsonb :meanings, default: []
      t.jsonb :tags, default: []
      t.integer :card_type
      t.integer :card_queue
      t.integer :interval_days, default: 0
      t.integer :ease_factor
      t.integer :review_count, default: 0
      t.integer :lapse_count, default: 0
      t.datetime :last_reviewed_at
      t.string :deck_name
      t.jsonb :note_fields, default: {}
      t.bigint :anki_note_id
      t.bigint :anki_card_id

      t.timestamps
    end

    add_index :anki_vocabs, :term
    add_index :anki_vocabs, :card_type
    add_index :anki_vocabs, :card_queue
    add_index :anki_vocabs, [ :user_id, :anki_card_id ], unique: true
  end
end
