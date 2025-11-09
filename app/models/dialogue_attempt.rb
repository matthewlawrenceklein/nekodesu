class DialogueAttempt < ApplicationRecord
  QUESTIONS_PER_ATTEMPT = 4

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

  def select_random_questions!
    all_question_ids = dialogue.comprehension_questions.pluck(:id)
    selected_ids = all_question_ids.sample(QUESTIONS_PER_ATTEMPT)
    update!(
      selected_question_ids: selected_ids,
      total_questions: QUESTIONS_PER_ATTEMPT
    )
  end

  def selected_questions
    return dialogue.comprehension_questions.none if selected_question_ids.empty?

    questions = dialogue.comprehension_questions.where(id: selected_question_ids).index_by(&:id)
    selected_question_ids.map { |id| questions[id] }.compact
  end
end
