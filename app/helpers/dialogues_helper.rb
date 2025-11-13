module DialoguesHelper
  def parse_dialogue_lines(dialogue_text)
    return [] if dialogue_text.blank?

    dialogue_text.split("\n").map do |line|
      next if line.strip.empty?

      if line.match(/^(.+?)[:：]\s*(.+)$/)
        { speaker: $1.strip, text: $2.strip }
      else
        { speaker: nil, text: line.strip }
      end
    end.compact
  end

  def character_avatar_image(character_name)
    images = {
      "田中さん" => "characters/tanaka.png",
      "山田くん" => "characters/yamada.png",
      "ゆみちゃん" => "characters/yumi.png",
      "小川先生" => "characters/ogawa.png"
    }

    images[character_name]
  end

  def character_avatar_color(character_name)
    colors = {
      "田中さん" => "bg-blue-500",
      "山田くん" => "bg-green-500",
      "ゆみちゃん" => "bg-pink-500",
      "小川先生" => "bg-purple-500"
    }

    colors[character_name] || "bg-gray-500"
  end

  def character_tts_voice(character_name)
    voices = {
      "田中さん" => "echo",
      "山田くん" => "verse",
      "ゆみちゃん" => "sage",
      "小川先生" => "ash"
    }

    voices[character_name] || "Yuri"
  end

  def message_alignment_class(speaker, first_speaker)
    if speaker == first_speaker
      "justify-start"
    else
      "justify-end"
    end
  end
end
