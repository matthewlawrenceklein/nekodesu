require 'rails_helper'

RSpec.describe WaniSubject, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:wani_study_materials).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:wani_subject) }

    it { should validate_presence_of(:external_id) }
    it { should validate_presence_of(:subject_type) }
    it { should validate_inclusion_of(:subject_type).in_array(WaniSubject::SUBJECT_TYPES) }
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:radical_1) { create(:wani_subject, user: user, subject_type: 'radical', level: 1) }
    let!(:kanji_1) { create(:wani_subject, user: user, subject_type: 'kanji', level: 2) }
    let!(:vocab_1) { create(:wani_subject, user: user, subject_type: 'vocabulary', level: 1) }
    let!(:radical_2) { create(:wani_subject, user: user, subject_type: 'radical', level: 1, hidden_at: Time.current) }

    it 'filters by subject type' do
      expect(user.wani_subjects.radicals.count).to eq(2)
      expect(user.wani_subjects.kanji.count).to eq(1)
      expect(user.wani_subjects.vocabulary.count).to eq(1)
    end

    it 'filters by level' do
      expect(user.wani_subjects.by_level(1).count).to eq(3)
      expect(user.wani_subjects.by_level(2).count).to eq(1)
    end

    it 'filters visible subjects' do
      expect(user.wani_subjects.visible.count).to eq(3)
    end
  end

  describe '#hidden?' do
    it 'returns true when hidden_at is present' do
      subject = build(:wani_subject, hidden_at: Time.current)
      expect(subject.hidden?).to be true
    end

    it 'returns false when hidden_at is nil' do
      subject = build(:wani_subject, hidden_at: nil)
      expect(subject.hidden?).to be false
    end
  end

  describe '#primary_meaning' do
    it 'returns the primary meaning' do
      subject = build(:wani_subject, meanings: [
        { 'meaning' => 'Ground', 'primary' => true },
        { 'meaning' => 'Floor', 'primary' => false }
      ])
      expect(subject.primary_meaning).to eq('Ground')
    end
  end

  describe '#primary_reading' do
    it 'returns the primary reading' do
      subject = build(:wani_subject, readings: [
        { 'reading' => 'いち', 'primary' => true },
        { 'reading' => 'ひと', 'primary' => false }
      ])
      expect(subject.primary_reading).to eq('いち')
    end
  end
end
