class WaniStudyMaterial < ApplicationRecord
  belongs_to :user
  belongs_to :wani_subject

  validates :external_id, presence: true, uniqueness: { scope: :user_id }
  validates :subject_id, presence: true
  validates :subject_type, presence: true

  scope :visible, -> { where(hidden: false) }
  scope :with_notes, -> { where.not(meaning_note: nil).or(where.not(reading_note: nil)) }
  scope :with_synonyms, -> { where("jsonb_array_length(meaning_synonyms) > 0") }
end
