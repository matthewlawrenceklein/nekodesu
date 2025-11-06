FactoryBot.define do
  factory :wani_study_material do
    user
    wani_subject
    sequence(:external_id)
    subject_id { wani_subject.external_id }
    subject_type { wani_subject.subject_type }
    meaning_note { nil }
    reading_note { nil }
    meaning_synonyms { [] }
    hidden { false }
    created_at_wanikani { Time.current }

    trait :with_notes do
      meaning_note { 'Custom meaning note' }
      reading_note { 'Custom reading note' }
    end

    trait :with_synonyms do
      meaning_synonyms { ['synonym1', 'synonym2'] }
    end

    trait :hidden do
      hidden { true }
    end
  end
end
