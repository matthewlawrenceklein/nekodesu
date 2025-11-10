class CreateRenshuuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :renshuu_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :renshuu_schedule, null: false, foreign_key: true
      t.integer :external_id
      t.string :item_type
      t.string :term
      t.string :reading
      t.jsonb :meanings
      t.string :grammar_point
      t.jsonb :example_sentences
      t.jsonb :tags
      t.integer :mastery_level

      t.timestamps
    end
  end
end
