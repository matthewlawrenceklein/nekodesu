FactoryBot.define do
  factory :dialogue do
    user
    japanese_text { "こんにちは。元気ですか？" }
    english_translation { "Hello. How are you?" }
    difficulty_level { "beginner" }
    min_level { 1 }
    max_level { 5 }
    vocabulary_used { [ "こんにちは", "元気" ] }
    kanji_used { [ "元", "気" ] }
    model_used { "anthropic/claude-3.5-sonnet" }
    generation_time_ms { 1500 }

    trait :intermediate do
      difficulty_level { "intermediate" }
      min_level { 10 }
      max_level { 20 }
      japanese_text { "昨日、図書館で面白い本を見つけました。" }
      english_translation { "Yesterday, I found an interesting book at the library." }
    end

    trait :advanced do
      difficulty_level { "advanced" }
      min_level { 30 }
      max_level { 50 }
      japanese_text { "経済的な観点から見ると、この政策は効果的だと思います。" }
      english_translation { "From an economic perspective, I think this policy is effective." }
    end
  end
end
