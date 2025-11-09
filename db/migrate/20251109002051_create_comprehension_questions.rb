class CreateComprehensionQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :comprehension_questions do |t|
      t.references :dialogue, null: false, foreign_key: true, index: true
      t.text :question_text, null: false
      t.jsonb :options, null: false, default: []
      t.integer :correct_option_index, null: false
      t.text :explanation

      t.timestamps
    end
  end
end
