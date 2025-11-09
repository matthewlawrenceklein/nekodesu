require 'rails_helper'

RSpec.describe ComprehensionQuestion, type: :model do
  describe 'associations' do
    it { should belong_to(:dialogue) }
  end

  describe 'validations' do
    it { should validate_presence_of(:question_text) }
    it { should validate_presence_of(:options) }
    it { should validate_presence_of(:correct_option_index) }

    it 'validates options is an array' do
      question = build(:comprehension_question, options: 'not an array')
      expect(question).not_to be_valid
      expect(question.errors[:options]).to include('must be an array')
    end

    it 'validates correct_option_index is within options range' do
      question = build(:comprehension_question, options: [ 'A', 'B' ], correct_option_index: 5)
      expect(question).not_to be_valid
      expect(question.errors[:correct_option_index]).to include('must be a valid index in options array')
    end
  end

  describe '#correct_answer' do
    it 'returns the correct answer from options' do
      question = build(:comprehension_question, options: [ 'Hello', 'Goodbye' ], correct_option_index: 0)
      expect(question.correct_answer).to eq('Hello')
    end

    it 'returns nil if index is out of range' do
      question = build(:comprehension_question, options: [ 'Hello' ], correct_option_index: 5)
      expect(question.correct_answer).to be_nil
    end
  end

  describe '#check_answer' do
    let(:question) { build(:comprehension_question, correct_option_index: 2) }

    it 'returns true for correct answer' do
      expect(question.check_answer(2)).to be true
    end

    it 'returns false for incorrect answer' do
      expect(question.check_answer(0)).to be false
    end
  end
end
