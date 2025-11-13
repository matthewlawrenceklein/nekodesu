class AddParticipantsToDialogues < ActiveRecord::Migration[8.1]
  def change
    add_column :dialogues, :participants, :jsonb, default: []
  end
end
