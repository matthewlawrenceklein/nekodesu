require "rails_helper"

RSpec.describe VocabularyFilterService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe "#filter_renshuu_vocabulary" do
    context "with no Renshuu vocabulary" do
      it "returns empty arrays" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to eq([])
        expect(result[:hiragana_only]).to eq([])
      end
    end

    context "with vocabulary containing no kanji" do
      before do
        create(:renshuu_item, user: user, item_type: "vocab", term: "ひらがな", reading: "ひらがな")
      end

      it "includes in safe vocabulary" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to include("ひらがな")
        expect(result[:hiragana_only]).to be_empty
      end
    end

    context "with vocabulary containing only known kanji" do
      before do
        create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
        create(:wani_subject, user: user, characters: "二", subject_type: "kanji")
        create(:renshuu_item, user: user, item_type: "vocab", term: "一二", reading: "いちに")
      end

      it "includes in safe vocabulary" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to include("一二")
        expect(result[:hiragana_only]).to be_empty
      end
    end

    context "with vocabulary containing unknown kanji" do
      before do
        create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
        create(:renshuu_item, user: user, item_type: "vocab", term: "一五", reading: "いちご")
      end

      it "includes reading in hiragana_only vocabulary" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to be_empty
        expect(result[:hiragana_only]).to include("いちご")
      end
    end

    context "with vocabulary containing unknown kanji but no reading" do
      before do
        create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
        create(:renshuu_item, user: user, item_type: "vocab", term: "一五", reading: nil)
      end

      it "skips the vocabulary" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to be_empty
        expect(result[:hiragana_only]).to be_empty
      end
    end

    context "with mixed vocabulary" do
      before do
        # Known kanji
        create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
        create(:wani_subject, user: user, characters: "二", subject_type: "kanji")
        create(:renshuu_item, user: user, term: "三", item_type: "kanji")

        # Safe vocab (all kanji known)
        create(:renshuu_item, user: user, item_type: "vocab", term: "一二", reading: "いちに")
        create(:renshuu_item, user: user, item_type: "vocab", term: "三", reading: "さん")

        # Hiragana-only vocab (has unknown kanji)
        create(:renshuu_item, user: user, item_type: "vocab", term: "五", reading: "ご")
        create(:renshuu_item, user: user, item_type: "vocab", term: "勉強", reading: "べんきょう")

        # No kanji
        create(:renshuu_item, user: user, item_type: "vocab", term: "ひらがな", reading: "ひらがな")
      end

      it "correctly categorizes all vocabulary" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to match_array([ "一二", "三", "ひらがな" ])
        expect(result[:hiragana_only]).to match_array([ "ご", "べんきょう" ])
      end
    end

    context "with Renshuu kanji subjects" do
      before do
        # WaniKani kanji
        create(:wani_subject, user: user, characters: "一", subject_type: "kanji")

        # Renshuu kanji
        create(:renshuu_item, user: user, term: "二", item_type: "kanji")

        # Vocab using both
        create(:renshuu_item, user: user, item_type: "vocab", term: "一二", reading: "いちに")
      end

      it "considers Renshuu kanji as known" do
        result = service.filter_renshuu_vocabulary

        expect(result[:safe]).to include("一二")
        expect(result[:hiragana_only]).to be_empty
      end
    end
  end
end
