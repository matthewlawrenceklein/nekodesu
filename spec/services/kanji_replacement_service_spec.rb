require "rails_helper"

RSpec.describe KanjiReplacementService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  before do
    # Set up known kanji
    create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
    create(:wani_subject, user: user, characters: "二", subject_type: "kanji")
    create(:renshuu_item, user: user, term: "三", item_type: "kanji")

    # Set up vocabulary with readings
    create(:renshuu_item, user: user, item_type: "vocab", term: "勉強", reading: "べんきょう")
    create(:renshuu_item, user: user, item_type: "vocab", term: "買い物", reading: "かいもの")
    create(:renshuu_item, user: user, item_type: "vocab", term: "一二三", reading: "いちにさん")
  end

  describe "#process_text" do
    context "when user prefers furigana mode" do
      before do
        user.update!(unknown_kanji_display_mode: "furigana")
      end

      it "adds ruby tags for words with unknown kanji" do
        text = "今日は勉強します"
        result = service.process_text(text)

        expect(result).to include("<ruby>勉強<rt>べんきょう</rt></ruby>")
        expect(result).to include("今日は")
        expect(result).to include("します")
      end

      it "handles multiple words with unknown kanji" do
        text = "勉強と買い物"
        result = service.process_text(text)

        expect(result).to include("<ruby>勉強<rt>べんきょう</rt></ruby>")
        expect(result).to include("<ruby>買い物<rt>かいもの</rt></ruby>")
      end

      it "returns original text when all kanji are known" do
        text = "一二三"
        result = service.process_text(text)

        expect(result).to eq(text)
      end

      it "doesn't double-process overlapping words" do
        text = "一二三"
        result = service.process_text(text)

        # Should not wrap the whole word since all kanji are known
        expect(result).not_to include("<ruby>")
      end
    end

    context "when user prefers hiragana mode" do
      before do
        user.update!(unknown_kanji_display_mode: "hiragana")
      end

      it "replaces words with unknown kanji with hiragana" do
        text = "今日は勉強します"
        result = service.process_text(text)

        expect(result).to include("べんきょう")
        expect(result).not_to include("勉強")
        expect(result).to include("今日は")
        expect(result).to include("します")
      end

      it "handles multiple words with unknown kanji" do
        text = "勉強と買い物"
        result = service.process_text(text)

        expect(result).to include("べんきょう")
        expect(result).to include("かいもの")
        expect(result).not_to include("勉強")
        expect(result).not_to include("買い物")
      end

      it "returns original text when all kanji are known" do
        text = "一二三"
        result = service.process_text(text)

        expect(result).to eq(text)
      end
    end

    context "with no unknown kanji" do
      it "returns original text unchanged" do
        text = "一二三"
        result = service.process_text(text)

        expect(result).to eq(text)
      end
    end

    context "with text containing no kanji" do
      it "returns original text unchanged" do
        text = "ひらがなだけです"
        result = service.process_text(text)

        expect(result).to eq(text)
      end
    end
  end
end
