require 'rails_helper'

RSpec.describe AnkiVocab, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
  end

  describe "validations" do
    it { should validate_presence_of(:anki_card_id) }

    it "validates uniqueness of anki_card_id scoped to user_id" do
      user = create(:user)
      create(:anki_vocab, user: user, anki_card_id: 123)
      duplicate = build(:anki_vocab, user: user, anki_card_id: 123)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:anki_card_id]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let(:user) { create(:user) }

    before do
      create(:anki_vocab, user: user, card_type: 0, card_queue: 0)
      create(:anki_vocab, user: user, card_type: 1, card_queue: 1)
      create(:anki_vocab, user: user, card_type: 2, card_queue: 2, interval_days: 30)
      create(:anki_vocab, user: user, card_type: 3, card_queue: 1)
      create(:anki_vocab, user: user, card_type: 2, card_queue: -1, interval_days: 25)
      create(:anki_vocab, user: user, card_type: 2, card_queue: 2, interval_days: 5)
      create(:anki_vocab, user: user, card_type: 2, card_queue: 2, interval_days: 21, lapse_count: 5)
    end

    it "filters new cards" do
      expect(AnkiVocab.new_cards.count).to eq(1)
    end

    it "filters learning cards" do
      expect(AnkiVocab.learning.count).to eq(1)
    end

    it "filters review cards" do
      expect(AnkiVocab.review.count).to eq(4)
    end

    it "filters relearning cards" do
      expect(AnkiVocab.relearning.count).to eq(1)
    end

    it "filters active cards" do
      expect(AnkiVocab.active.count).to eq(6)
    end

    it "filters suspended cards" do
      expect(AnkiVocab.suspended.count).to eq(1)
    end

    it "filters well-known cards" do
      expect(AnkiVocab.well_known.count).to eq(3)
    end

    it "filters struggling cards" do
      expect(AnkiVocab.struggling.count).to eq(1)
    end
  end

  describe "#mastery_level" do
    let(:user) { create(:user) }

    it "returns :new for new cards" do
      vocab = create(:anki_vocab, user: user, card_type: 0)
      expect(vocab.mastery_level).to eq(:new)
    end

    it "returns :learning for learning cards" do
      vocab = create(:anki_vocab, user: user, card_type: 1)
      expect(vocab.mastery_level).to eq(:learning)
    end

    it "returns :relearning for relearning cards" do
      vocab = create(:anki_vocab, user: user, card_type: 3)
      expect(vocab.mastery_level).to eq(:relearning)
    end

    it "returns :struggling for cards with high lapse count" do
      vocab = create(:anki_vocab, user: user, card_type: 2, lapse_count: 5)
      expect(vocab.mastery_level).to eq(:struggling)
    end

    it "returns :master for review cards with 120+ day interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 150)
      expect(vocab.mastery_level).to eq(:master)
    end

    it "returns :proficient for review cards with 60+ day interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 75)
      expect(vocab.mastery_level).to eq(:proficient)
    end

    it "returns :familiar for review cards with 21+ day interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 30)
      expect(vocab.mastery_level).to eq(:familiar)
    end

    it "returns :learning for review cards with low interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 5)
      expect(vocab.mastery_level).to eq(:learning)
    end
  end

  describe "#known?" do
    let(:user) { create(:user) }

    it "returns true for review cards with 21+ day interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 30)
      expect(vocab.known?).to be true
    end

    it "returns false for review cards with low interval" do
      vocab = create(:anki_vocab, user: user, card_type: 2, interval_days: 10)
      expect(vocab.known?).to be false
    end

    it "returns false for non-review cards" do
      vocab = create(:anki_vocab, user: user, card_type: 1, interval_days: 30)
      expect(vocab.known?).to be false
    end
  end
end
