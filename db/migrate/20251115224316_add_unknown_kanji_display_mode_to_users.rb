class AddUnknownKanjiDisplayModeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :unknown_kanji_display_mode, :string, default: "furigana", null: false
  end
end
