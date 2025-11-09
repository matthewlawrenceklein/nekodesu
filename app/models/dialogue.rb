class Dialogue < ApplicationRecord
  DIFFICULTY_LEVELS = %w[beginner intermediate advanced].freeze

  belongs_to :user
  has_many :comprehension_questions, dependent: :destroy

  validates :japanese_text, presence: true
  validates :english_translation, presence: true
  validates :difficulty_level, presence: true, inclusion: { in: DIFFICULTY_LEVELS }
  validates :min_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 60, allow_nil: true }
  validates :max_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 60, allow_nil: true }

  scope :by_difficulty, ->(level) { where(difficulty_level: level) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_level_range, ->(min, max) { where("min_level >= ? AND max_level <= ?", min, max) }

  def beginner?
    difficulty_level == "beginner"
  end

  def intermediate?
    difficulty_level == "intermediate"
  end

  def advanced?
    difficulty_level == "advanced"
  end

  def level_range
    return nil unless min_level && max_level

    "#{min_level}-#{max_level}"
  end
end
