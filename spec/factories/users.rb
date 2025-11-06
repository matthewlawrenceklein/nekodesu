FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    wanikani_api_key { "test_api_key_#{SecureRandom.hex(8)}" }
    last_wanikani_sync { nil }
  end
end
