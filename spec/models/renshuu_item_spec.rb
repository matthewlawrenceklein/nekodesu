require "rails_helper"

RSpec.describe RenshuuItem, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it "validates presence of external_id" do
      item = build(:renshuu_item, external_id: nil)
      expect(item).not_to be_valid
      expect(item.errors[:external_id]).to be_present
    end

    it "validates presence of item_type" do
      item = build(:renshuu_item, item_type: nil)
      expect(item).not_to be_valid
      expect(item.errors[:item_type]).to be_present
    end

    it "validates item_type is in allowed list" do
      item = build(:renshuu_item, item_type: "invalid")
      expect(item).not_to be_valid
      expect(item.errors[:item_type]).to be_present
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }
    let!(:vocab) { create(:renshuu_item, user: user, item_type: "vocab") }
    let!(:grammar) { create(:renshuu_item, user: user, item_type: "grammar") }
    let!(:kanji) { create(:renshuu_item, user: user, item_type: "kanji") }
    let!(:sentence) { create(:renshuu_item, user: user, item_type: "sentence") }

    it "filters by item type" do
      expect(user.renshuu_items.vocab).to include(vocab)
      expect(user.renshuu_items.grammar).to include(grammar)
      expect(user.renshuu_items.kanji).to include(kanji)
      expect(user.renshuu_items.sentences).to include(sentence)
    end
  end
end
