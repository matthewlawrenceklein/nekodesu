FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    wanikani_api_key { "test_wanikani_key_#{SecureRandom.hex(8)}" }
    renshuu_api_key { "test_renshuu_key_#{SecureRandom.hex(8)}" }
    openrouter_api_key { "test_openrouter_key_#{SecureRandom.hex(8)}" }
    openai_api_key { "test_openai_key_#{SecureRandom.hex(8)}" }
    speech_speed { 1.0 }
    last_wanikani_sync { nil }
  end
end
