require 'rails_helper'

RSpec.describe WaniStudyMaterial, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:wani_subject) }
  end

  describe 'validations' do
    subject { build(:wani_study_material) }

    it { should validate_presence_of(:external_id) }
    it { should validate_presence_of(:subject_id) }
    it { should validate_presence_of(:subject_type) }
  end

  describe 'scopes' do
    let!(:user) { create(:user) }
    let!(:subject1) { create(:wani_subject, user: user) }
    let!(:subject2) { create(:wani_subject, user: user) }
    let!(:material_with_note) { create(:wani_study_material, user: user, wani_subject: subject1, hidden: false, meaning_note: 'test note') }
    let!(:material_hidden) { create(:wani_study_material, user: user, wani_subject: subject2, hidden: true) }
    let!(:material_with_synonyms) { create(:wani_study_material, user: user, wani_subject: subject1, meaning_synonyms: [ 'test' ]) }

    it 'filters visible study materials' do
      expect(user.wani_study_materials.visible.count).to eq(2)
    end

    it 'filters study materials with notes' do
      expect(user.wani_study_materials.with_notes.count).to eq(1)
    end

    it 'filters study materials with synonyms' do
      expect(user.wani_study_materials.with_synonyms.count).to eq(1)
    end
  end
end
