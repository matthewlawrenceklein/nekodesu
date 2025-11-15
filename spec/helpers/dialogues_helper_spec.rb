require 'rails_helper'

RSpec.describe DialoguesHelper, type: :helper do
  describe '#parse_dialogue_lines' do
    it 'parses dialogue with colon separator' do
      text = "田中さん: こんにちは\n山田くん: 元気ですか"
      result = helper.parse_dialogue_lines(text)

      expect(result.length).to eq(2)
      expect(result[0]).to eq({ speaker: "田中さん", text: "こんにちは" })
      expect(result[1]).to eq({ speaker: "山田くん", text: "元気ですか" })
    end

    it 'parses dialogue with Japanese colon separator' do
      text = "田中さん：こんにちは"
      result = helper.parse_dialogue_lines(text)

      expect(result.length).to eq(1)
      expect(result[0]).to eq({ speaker: "田中さん", text: "こんにちは" })
    end

    it 'handles empty lines' do
      text = "田中さん: こんにちは\n\n山田くん: 元気ですか"
      result = helper.parse_dialogue_lines(text)

      expect(result.length).to eq(2)
    end

    it 'handles blank text' do
      expect(helper.parse_dialogue_lines("")).to eq([])
      expect(helper.parse_dialogue_lines(nil)).to eq([])
    end

    it 'handles lines without speaker' do
      text = "田中さん: こんにちは\nこれはナレーション"
      result = helper.parse_dialogue_lines(text)

      expect(result.length).to eq(2)
      expect(result[1]).to eq({ speaker: nil, text: "これはナレーション" })
    end
  end

  describe '#character_avatar_image' do
    it 'returns image path for 田中さん' do
      expect(helper.character_avatar_image("田中さん")).to eq("characters/tanaka.png")
    end

    it 'returns image path for 山田くん' do
      expect(helper.character_avatar_image("山田くん")).to eq("characters/yamada.png")
    end

    it 'returns image path for ゆみちゃん' do
      expect(helper.character_avatar_image("ゆみちゃん")).to eq("characters/yumi.png")
    end

    it 'returns image path for 小川先生' do
      expect(helper.character_avatar_image("小川先生")).to eq("characters/ogawa.png")
    end

    it 'returns nil for unknown character' do
      expect(helper.character_avatar_image("Unknown")).to be_nil
    end
  end

  describe '#character_avatar_color' do
    it 'returns blue for 田中さん' do
      expect(helper.character_avatar_color("田中さん")).to eq("bg-blue-500")
    end

    it 'returns green for 山田くん' do
      expect(helper.character_avatar_color("山田くん")).to eq("bg-green-500")
    end

    it 'returns pink for ゆみちゃん' do
      expect(helper.character_avatar_color("ゆみちゃん")).to eq("bg-pink-500")
    end

    it 'returns purple for 小川先生' do
      expect(helper.character_avatar_color("小川先生")).to eq("bg-purple-500")
    end

    it 'returns gray for unknown character' do
      expect(helper.character_avatar_color("Unknown")).to eq("bg-gray-500")
    end
  end

  describe '#character_tts_voice' do
    it 'returns echo for 田中さん' do
      expect(helper.character_tts_voice("田中さん")).to eq("echo")
    end

    it 'returns onyx for 山田くん' do
      expect(helper.character_tts_voice("山田くん")).to eq("onyx")
    end

    it 'returns nova for ゆみちゃん' do
      expect(helper.character_tts_voice("ゆみちゃん")).to eq("nova")
    end

    it 'returns fable for 小川先生' do
      expect(helper.character_tts_voice("小川先生")).to eq("fable")
    end

    it 'returns alloy for unknown character' do
      expect(helper.character_tts_voice("Unknown")).to eq("alloy")
    end
  end

  describe '#character_tts_instructions' do
    it 'returns friendly instructions for 田中さん' do
      instructions = helper.character_tts_instructions("田中さん")
      expect(instructions).to include("Friendly, warm, approachable")
      expect(instructions).to include("Casual, upbeat, helpful")
    end

    it 'returns determined instructions for 山田くん' do
      instructions = helper.character_tts_instructions("山田くん")
      expect(instructions).to include("Determined, confident, passionate")
      expect(instructions).to include("Excited, motivational")
    end

    it 'returns playful instructions for ゆみちゃん' do
      instructions = helper.character_tts_instructions("ゆみちゃん")
      expect(instructions).to include("Playful, witty, clever")
      expect(instructions).to include("Sarcastic but friendly")
    end

    it 'returns authoritative instructions for 小川先生' do
      instructions = helper.character_tts_instructions("小川先生")
      expect(instructions).to include("Authoritative, wise, gruff")
      expect(instructions).to include("Serious, measured")
    end

    it 'returns default instructions for unknown character' do
      instructions = helper.character_tts_instructions("Unknown")
      expect(instructions).to include("Natural, conversational")
      expect(instructions).to include("Neutral and friendly")
    end
  end

  describe '#message_alignment_class' do
    it 'returns justify-start for first speaker' do
      expect(helper.message_alignment_class("田中さん", "田中さん")).to eq("justify-start")
    end

    it 'returns justify-end for second speaker' do
      expect(helper.message_alignment_class("山田くん", "田中さん")).to eq("justify-end")
    end
  end

  describe '#unknown_kanji_in_text' do
    let(:user) { create(:user) }

    before do
      create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
      create(:wani_subject, user: user, characters: "二", subject_type: "kanji")
      create(:wani_subject, user: user, characters: "三", subject_type: "kanji")
      create(:renshuu_item, user: user, term: "四", item_type: "kanji")
    end

    it 'returns empty array when text is blank' do
      expect(helper.unknown_kanji_in_text("", user)).to eq([])
    end

    it 'returns empty array when user is nil' do
      expect(helper.unknown_kanji_in_text("一二三", nil)).to eq([])
    end

    it 'returns empty array when all kanji are known' do
      text = "一二三四"
      expect(helper.unknown_kanji_in_text(text, user)).to eq([])
    end

    it 'identifies unknown kanji from WaniKani' do
      text = "一五"
      expect(helper.unknown_kanji_in_text(text, user)).to eq([ "五" ])
    end

    it 'identifies multiple unknown kanji' do
      text = "一五六七"
      unknown = helper.unknown_kanji_in_text(text, user)
      expect(unknown).to match_array([ "五", "六", "七" ])
    end

    it 'does not consider kanji from vocabulary as known unless explicitly studied' do
      # User has vocabulary 野球 but hasn't studied the individual kanji
      create(:wani_subject, user: user, characters: "野球", subject_type: "vocabulary")
      text = "野球"
      # Both kanji should be marked as unknown since they're not in kanji subjects
      expect(helper.unknown_kanji_in_text(text, user)).to match_array([ "野", "球" ])
    end

    it 'considers kanji known when explicitly studied' do
      # User has the individual kanji as subjects
      create(:wani_subject, user: user, characters: "野", subject_type: "kanji")
      create(:wani_subject, user: user, characters: "球", subject_type: "kanji")
      text = "野球"
      expect(helper.unknown_kanji_in_text(text, user)).to eq([])
    end
  end

  describe '#add_furigana_to_unknown_kanji' do
    let(:user) { create(:user) }

    before do
      create(:wani_subject, user: user, characters: "一", subject_type: "kanji")
    end

    it 'returns original text when no unknown kanji' do
      text = "一"
      expect(helper.add_furigana_to_unknown_kanji(text, user)).to eq(text)
    end

    it 'wraps unknown kanji with span tag' do
      text = "一五"
      result = helper.add_furigana_to_unknown_kanji(text, user)
      expect(result).to include('<span class="unknown-kanji"')
      expect(result).to include("五")
    end

    it 'returns html_safe string' do
      text = "一五"
      result = helper.add_furigana_to_unknown_kanji(text, user)
      expect(result).to be_html_safe
    end
  end
end
