class DialogueAttempt < ApplicationRecord
  belongs_to :user
  belongs_to :dialogue

  validates :correct_count, numericality: { greater_than_or_equal_to: 0 }
  validates :total_questions, numericality: { greater_than_or_equal_to: 0 }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where(completed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def score_percentage
    return 0 if total_questions.zero?

    (correct_count.to_f / total_questions * 100).round
  end

  def completed?
    completed_at.present?
  end

  def mark_completed!
    update!(completed_at: Time.current)
  end
end
