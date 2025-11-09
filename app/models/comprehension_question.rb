class ComprehensionQuestion < ApplicationRecord
  belongs_to :dialogue

  validates :question_text, presence: true
  validates :options, presence: true
  validates :correct_option_index, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :options_must_be_array
  validate :correct_option_index_must_be_valid

  def correct_answer
    options[correct_option_index] if options.is_a?(Array) && correct_option_index < options.length
  end

  def check_answer(selected_index)
    selected_index == correct_option_index
  end

  private

  def options_must_be_array
    return if options.is_a?(Array)

    errors.add(:options, "must be an array")
  end

  def correct_option_index_must_be_valid
    return unless options.is_a?(Array)
    return unless correct_option_index.present?
    return if correct_option_index >= 0 && correct_option_index < options.length

    errors.add(:correct_option_index, "must be a valid index in options array")
  end
end
