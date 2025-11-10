FactoryBot.define do
  factory :renshuu_item do
    user
    sequence(:external_id)
    item_type { "vocab" }
    term { "食べる" }
    reading { "たべる" }
    meanings { [ "to eat" ] }
    grammar_point { nil }
    example_sentences { [] }
    tags { [] }
    mastery_level { 50 }
  end
end
