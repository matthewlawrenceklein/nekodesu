class AddAudioFilesToDialogues < ActiveRecord::Migration[8.1]
  def change
    add_column :dialogues, :audio_files, :jsonb, default: []
  end
end
