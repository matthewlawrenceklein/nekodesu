FactoryBot.define do
  factory :wani_subject do
    user
    sequence(:external_id)
    subject_type { 'kanji' }
    characters { '一' }
    slug { 'one' }
    level { 1 }
    lesson_position { 1 }
    meaning_mnemonic { 'Test mnemonic for meaning' }
    reading_mnemonic { 'Test mnemonic for reading' }
    document_url { 'https://www.wanikani.com/kanji/one' }
    meanings { [{ 'meaning' => 'One', 'primary' => true, 'accepted_answer' => true }] }
    auxiliary_meanings { [] }
    readings { [{ 'reading' => 'いち', 'primary' => true, 'accepted_answer' => true, 'type' => 'onyomi' }] }
    component_subject_ids { [] }
    hidden_at { nil }
    created_at_wanikani { Time.current }

    trait :radical do
      subject_type { 'radical' }
      readings { [] }
    end

    trait :vocabulary do
      subject_type { 'vocabulary' }
    end

    trait :kana_vocabulary do
      subject_type { 'kana_vocabulary' }
    end

    trait :hidden do
      hidden_at { Time.current }
    end
  end
end
