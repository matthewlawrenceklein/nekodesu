class AddSelectedQuestionsToDialogueAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :dialogue_attempts, :selected_question_ids, :jsonb, default: [], null: false
  end
end
