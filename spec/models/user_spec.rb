require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:wani_subjects).dependent(:destroy) }
    it { should have_many(:wani_study_materials).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    
    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'validates email uniqueness' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      expect(duplicate_user).not_to be_valid
    end
  end

  describe '#wanikani_configured?' do
    it 'returns true when api key is present' do
      user = build(:user, wanikani_api_key: 'test_key')
      expect(user.wanikani_configured?).to be true
    end

    it 'returns false when api key is blank' do
      user = build(:user, wanikani_api_key: nil)
      expect(user.wanikani_configured?).to be false
    end
  end
end
