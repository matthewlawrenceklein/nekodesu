FactoryBot.define do
  factory :anki_vocab do
    user
    sequence(:anki_card_id) { |n| n }
    sequence(:anki_note_id) { |n| n }
    term { "日本語" }
    reading { "にほんご" }
    meanings { [ "Japanese language", "Japanese" ] }
    tags { [ "vocabulary", "jlpt-n5" ] }
    card_type { 2 }
    card_queue { 2 }
    interval_days { 30 }
    ease_factor { 2500 }
    review_count { 10 }
    lapse_count { 0 }
    last_reviewed_at { 1.day.ago }
    deck_name { "Japanese Core 2000" }
    note_fields { [ "日本語", "にほんご", "Japanese language" ] }
  end
end
