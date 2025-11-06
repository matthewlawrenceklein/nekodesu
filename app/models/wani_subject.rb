class WaniSubject < ApplicationRecord
  belongs_to :user
  has_many :wani_study_materials, dependent: :destroy

  SUBJECT_TYPES = %w[radical kanji vocabulary kana_vocabulary].freeze

  validates :external_id, presence: true, uniqueness: { scope: :user_id }
  validates :subject_type, presence: true, inclusion: { in: SUBJECT_TYPES }
  validates :level, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 60 }, allow_nil: true

  scope :radicals, -> { where(subject_type: 'radical') }
  scope :kanji, -> { where(subject_type: 'kanji') }
  scope :vocabulary, -> { where(subject_type: 'vocabulary') }
  scope :kana_vocabulary, -> { where(subject_type: 'kana_vocabulary') }
  scope :by_level, ->(level) { where(level: level) }
  scope :visible, -> { where(hidden_at: nil) }

  def hidden?
    hidden_at.present?
  end

  def primary_meaning
    meanings.find { |m| m['primary'] }&.dig('meaning')
  end

  def primary_reading
    readings.find { |r| r['primary'] }&.dig('reading')
  end
end
