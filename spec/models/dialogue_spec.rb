require 'rails_helper'

RSpec.describe Dialogue, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:comprehension_questions).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:japanese_text) }
    it { should validate_presence_of(:english_translation) }
    it { should validate_presence_of(:difficulty_level) }
    it { should validate_inclusion_of(:difficulty_level).in_array(Dialogue::DIFFICULTY_LEVELS) }
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:beginner_dialogue) { create(:dialogue, user: user, difficulty_level: 'beginner') }
    let!(:intermediate_dialogue) { create(:dialogue, :intermediate, user: user) }
    let!(:advanced_dialogue) { create(:dialogue, :advanced, user: user) }

    describe '.by_difficulty' do
      it 'filters by difficulty level' do
        expect(Dialogue.by_difficulty('beginner')).to include(beginner_dialogue)
        expect(Dialogue.by_difficulty('beginner')).not_to include(intermediate_dialogue)
      end
    end

    describe '.recent' do
      it 'orders by created_at descending' do
        expect(Dialogue.recent.first).to eq(advanced_dialogue)
      end
    end

    describe '.for_level_range' do
      it 'filters by level range' do
        dialogues = Dialogue.for_level_range(1, 10)
        expect(dialogues).to include(beginner_dialogue)
        expect(dialogues).not_to include(advanced_dialogue)
      end
    end
  end

  describe 'difficulty level methods' do
    it 'returns true for beginner?' do
      dialogue = build(:dialogue, difficulty_level: 'beginner')
      expect(dialogue.beginner?).to be true
      expect(dialogue.intermediate?).to be false
    end

    it 'returns true for intermediate?' do
      dialogue = build(:dialogue, :intermediate)
      expect(dialogue.intermediate?).to be true
      expect(dialogue.beginner?).to be false
    end

    it 'returns true for advanced?' do
      dialogue = build(:dialogue, :advanced)
      expect(dialogue.advanced?).to be true
      expect(dialogue.beginner?).to be false
    end
  end

  describe '#level_range' do
    it 'returns formatted level range' do
      dialogue = build(:dialogue, min_level: 5, max_level: 10)
      expect(dialogue.level_range).to eq('5-10')
    end

    it 'returns nil if levels are not set' do
      dialogue = build(:dialogue, min_level: nil, max_level: nil)
      expect(dialogue.level_range).to be_nil
    end
  end
end
