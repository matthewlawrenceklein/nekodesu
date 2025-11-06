class CreateWaniSubjects < ActiveRecord::Migration[8.1]
  def change
    create_table :wani_subjects do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :external_id, null: false
      t.string :subject_type, null: false
      t.string :characters
      t.string :slug
      t.integer :level
      t.integer :lesson_position
      t.text :meaning_mnemonic
      t.text :reading_mnemonic
      t.string :document_url
      t.jsonb :meanings, default: []
      t.jsonb :auxiliary_meanings, default: []
      t.jsonb :readings, default: []
      t.jsonb :component_subject_ids, default: []
      t.datetime :hidden_at
      t.datetime :created_at_wanikani

      t.timestamps
    end

    add_index :wani_subjects, [:user_id, :external_id], unique: true
    add_index :wani_subjects, :subject_type
    add_index :wani_subjects, :level
  end
end
