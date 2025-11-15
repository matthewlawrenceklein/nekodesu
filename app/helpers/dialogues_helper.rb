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
      "山田くん" => "onyx",
      "ゆみちゃん" => "nova",
      "小川先生" => "fable"
    }

    voices[character_name] || "alloy"
  end

  def character_tts_instructions(character_name)
    instructions = {
      "田中さん" => <<~INSTRUCTIONS.strip,
        Voice Affect: Friendly, warm, approachable, and energetic. Young adult with positive demeanor.

        Tone: Casual, upbeat, helpful, and welcoming. Natural conversational style of a service worker.

        Pacing: Moderate to slightly fast, reflecting youthful energy and enthusiasm. Consistent rhythm with natural flow.

        Emotions: Cheerful, welcoming, enthusiastic. Genuine friendliness and desire to help.

        Pronunciation: Clear and natural. Emphasis on polite expressions and service-oriented language.

        Pauses: Natural conversational pauses. Brief pauses before greetings and after questions to allow response space.
      INSTRUCTIONS
      "山田くん" => <<~INSTRUCTIONS.strip,
        Voice Affect: Determined, confident, passionate, and driven. High school athlete with competitive spirit.

        Tone: Excited, motivational, slightly competitive. Energetic with strong conviction.

        Pacing: Fast when excited about goals or achievements. Emphatic on key motivational points. Slower for serious commitments.

        Emotions: Enthusiasm, determination, pride, ambition. Occasional frustration when facing challenges.

        Pronunciation: Clear and strong. Emphasis on action words and achievements. Slightly forceful on commitments.

        Pauses: Brief pauses for emphasis before important declarations. Quick transitions reflecting high energy.
      INSTRUCTIONS
      "ゆみちゃん" => <<~INSTRUCTIONS.strip,
        Voice Affect: Playful, witty, clever, and teasing. Middle school girl with mischievous personality.

        Tone: Sarcastic but friendly, humorous, lighthearted. Teasing without malice.

        Pacing: Variable - quick and animated for jokes and teasing. Deliberately slower for sarcastic remarks. Playful rhythm changes.

        Emotions: Mischievous, amused, friendly, clever. Occasional mock exasperation for comedic effect.

        Pronunciation: Expressive and animated. Exaggerated emphasis on sarcastic points. Playful tone shifts.

        Pauses: Strategic pauses before punchlines. Brief pauses after sarcastic remarks for effect. Natural conversational flow.
      INSTRUCTIONS
      "小川先生" => <<~INSTRUCTIONS.strip
        Voice Affect: Authoritative, wise, gruff but caring. Retired professor commanding respect with underlying warmth.

        Tone: Serious, measured, occasionally stern but ultimately supportive. Professorial and thoughtful.

        Pacing: Slower and deliberate. Thoughtful pauses between ideas. Measured delivery reflecting careful consideration.

        Emotions: Stern wisdom, subtle warmth beneath gruff exterior, gravitas. Occasional gentle encouragement.

        Pronunciation: Precise and articulate. Emphasis on important concepts and lessons. Slightly formal speech patterns.

        Pauses: Longer thoughtful pauses before advice. Deliberate pauses after important points for reflection. Professorial timing.
      INSTRUCTIONS
    }

    instructions[character_name] || <<~INSTRUCTIONS.strip
      Voice Affect: Natural, conversational, and clear.

      Tone: Neutral and friendly.

      Pacing: Moderate, natural conversational speed.

      Emotions: Calm and balanced.

      Pronunciation: Clear and natural.

      Pauses: Natural conversational pauses.
    INSTRUCTIONS
  end

  def message_alignment_class(speaker, first_speaker)
    if speaker == first_speaker
      "justify-start"
    else
      "justify-end"
    end
  end
end
