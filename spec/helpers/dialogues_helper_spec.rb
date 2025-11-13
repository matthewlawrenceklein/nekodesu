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

  describe '#message_alignment_class' do
    it 'returns justify-start for first speaker' do
      expect(helper.message_alignment_class("田中さん", "田中さん")).to eq("justify-start")
    end

    it 'returns justify-end for second speaker' do
      expect(helper.message_alignment_class("山田くん", "田中さん")).to eq("justify-end")
    end
  end
end
