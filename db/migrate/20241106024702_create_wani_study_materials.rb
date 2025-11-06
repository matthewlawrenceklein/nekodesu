class CreateWaniStudyMaterials < ActiveRecord::Migration[8.1]
  def change
    create_table :wani_study_materials do |t|
      t.references :user, null: false, foreign_key: true
      t.references :wani_subject, null: false, foreign_key: true
      t.integer :external_id, null: false
      t.integer :subject_id, null: false
      t.string :subject_type, null: false
      t.text :meaning_note
      t.text :reading_note
      t.jsonb :meaning_synonyms, default: []
      t.boolean :hidden, default: false
      t.datetime :created_at_wanikani

      t.timestamps
    end

    add_index :wani_study_materials, [ :user_id, :external_id ], unique: true
    add_index :wani_study_materials, :subject_id
  end
end
