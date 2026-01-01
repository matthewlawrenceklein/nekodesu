class DialogueGenerationService
  class GenerationError < StandardError; end

  # Vocabulary sampling limits to balance variety with token constraints
  WANIKANI_KANJI_SAMPLE_SIZE = 150
  WANIKANI_VOCAB_SAMPLE_SIZE = 200
  RENSHUU_KANJI_SAMPLE_SIZE = 150
  RENSHUU_VOCAB_SAMPLE_SIZE = 200
  ANKI_VOCAB_SAMPLE_SIZE = 200
  MAX_KANJI_FOR_PROMPT = 200
  MAX_VOCAB_FOR_PROMPT = 300

  # Available dialogue characters
  CHARACTERS = [
    {
      name: "田中さん",
      name_romaji: "Tanaka-san",
      age_group: "young adult",
      occupation: "convenience store worker",
      personality: "friendly, knows all the customers"
    },
    {
      name: "山田くん",
      name_romaji: "Yamada-kun",
      age_group: "high school student",
      occupation: "athlete",
      personality: "friendly and excited"
    },
    {
      name: "ゆみちゃん",
      name_romaji: "Yumi-chan",
      age_group: "middle school student",
      occupation: "student",
      personality: "nerd, shy but always happy to talk about her interests"
    },
    {
      name: "小川先生",
      name_romaji: "Ogawa-sensei",
      age_group: "retired",
      occupation: "retired university professor",
      personality: "gruff but knowledgeable, gives great advice"
    }
  ].freeze

  def initialize(user, difficulty_level: "beginner")
    @user = user
    @difficulty_level = difficulty_level
    raise GenerationError, "OpenRouter API key not configured" unless user.openrouter_configured?
    @openrouter_client = OpenrouterClient.new(user.openrouter_api_key)
  end

  def generate
    start_time = Time.current

    vocabulary_data = build_vocabulary_data
    prompt = build_prompt(vocabulary_data)

    response = @openrouter_client.chat_completion(
      messages: [
        { role: "system", content: system_prompt },
        { role: "user", content: prompt }
      ],
      model: "openai/gpt-4o",
      max_tokens: 2000,
      temperature: 0.7
    )

    generation_time = ((Time.current - start_time) * 1000).to_i

    parse_and_create_dialogue(response, vocabulary_data, generation_time)
  rescue OpenrouterClient::ApiError => e
    raise GenerationError, "Failed to generate dialogue: #{e.message}"
  end

  private

  def build_vocabulary_data
    level_range = level_range_for_difficulty

    # Get WaniKani vocabulary and kanji (random sample from level range)
    wani_kanji = @user.wani_subjects
                      .visible
                      .kanji
                      .where(level: level_range)
                      .order("RANDOM()")
                      .limit(WANIKANI_KANJI_SAMPLE_SIZE)
                      .pluck(:characters)
                      .compact

    wani_vocab = @user.wani_subjects
                      .visible
                      .vocabulary
                      .where(level: level_range)
                      .order("RANDOM()")
                      .limit(WANIKANI_VOCAB_SAMPLE_SIZE)
                      .pluck(:characters)
                      .compact

    # Get Renshuu kanji (random sample)
    renshuu_kanji = @user.renshuu_items
                         .kanji
                         .order("RANDOM()")
                         .limit(RENSHUU_KANJI_SAMPLE_SIZE)
                         .pluck(:term)
                         .compact

    # Get Anki vocabulary (well-known cards only)
    anki_vocab = @user.anki_vocabs
                      .well_known
                      .active
                      .order("RANDOM()")
                      .limit(ANKI_VOCAB_SAMPLE_SIZE)
                      .pluck(:term)
                      .compact

    # Smart filtering of Renshuu vocabulary
    # Separates into safe vocab (all kanji known) and hiragana-only vocab (unknown kanji)
    filter_service = VocabularyFilterService.new(@user)
    renshuu_filtered = filter_service.filter_renshuu_vocabulary

    # Combine WaniKani vocab with safe Renshuu vocab and Anki vocab
    combined_kanji = (wani_kanji + renshuu_kanji).uniq
    combined_vocab = (wani_vocab + renshuu_filtered[:safe] + anki_vocab).uniq

    # Limit to reasonable totals for the AI (to avoid token limits)
    final_kanji = combined_kanji.sample([ combined_kanji.length, MAX_KANJI_FOR_PROMPT ].min)
    final_vocab = combined_vocab.sample([ combined_vocab.length, MAX_VOCAB_FOR_PROMPT ].min)

    # Sample hiragana-only vocabulary (limited to avoid overwhelming the prompt)
    hiragana_vocab = renshuu_filtered[:hiragana_only].sample(100)

    {
      kanji: final_kanji,
      vocabulary: final_vocab,
      hiragana_vocabulary: hiragana_vocab,
      min_level: level_range.min,
      max_level: level_range.max,
      sources: {
        wanikani: { kanji: wani_kanji.count, vocab: wani_vocab.count },
        renshuu: {
          kanji: renshuu_kanji.count,
          vocab_safe: renshuu_filtered[:safe].count,
          vocab_hiragana: renshuu_filtered[:hiragana_only].count
        },
        anki: { vocab: anki_vocab.count },
        total: {
          kanji: final_kanji.count,
          vocab: final_vocab.count,
          hiragana_vocab: hiragana_vocab.count
        }
      }
    }
  end

  def level_range_for_difficulty
    case @difficulty_level
    when "beginner"
      1..10
    when "intermediate"
      11..30
    when "advanced"
      31..60
    else
      1..10
    end
  end

  def system_prompt
    <<~PROMPT
      You are a Japanese language teacher creating reading comprehension exercises.
      Your task is to generate a natural Japanese dialogue using ONLY the vocabulary and kanji provided by the user.
      The vocabulary comes from the user's WaniKani, Renshuu, and Anki study materials.

      CRITICAL CONSTRAINT - VOCABULARY RESTRICTION:
      You MUST use ONLY the kanji and vocabulary words provided in the user's message.
      DO NOT use any kanji or vocabulary that is not explicitly listed.
      If a kanji appears in the provided vocabulary list, you may use it.
      If a kanji does NOT appear in either the "Available Kanji" or within the "Available Vocabulary" lists, you MUST NOT use it.
      This is a strict requirement - the user is a language learner and can only read the words they have studied.
      Using unknown words defeats the purpose of this exercise.

      Requirements:
      1. Choose EXACTLY 2 characters from the provided character list to participate in the dialogue
      2. Create dialogue content that is consistent with the chosen characters' personalities, age groups, and occupations
      3. **STRICTLY USE ONLY** the kanji and vocabulary words provided (from both WaniKani and Renshuu)
      4. Create a natural, conversational dialogue that reflects the relationship between the characters
      5. Match the grammar complexity and formality to the difficulty level:
         - Beginner (N5): Simple present/past tense, basic particles (は、が、を、に、で), polite form (です/ます)
         - Intermediate (N4-N3): More complex particles, て-form, conditionals, casual and polite forms
         - Advanced (N2-N1): Complex grammar, honorifics/humble forms, nuanced expressions, literary style
      6. Include EXACTLY 10 comprehension questions with 4 multiple choice options each
      7. Questions should test different aspects: vocabulary, grammar, context, inference
      8. Provide English translations

      REMINDER: Every kanji character in your dialogue MUST appear in either the "Available Kanji" list OR within one of the words in the "Available Vocabulary" list. No exceptions.

      Format your response as JSON with this structure:
      {
        "participants": ["Character Name 1", "Character Name 2"],
        "japanese_text": "The dialogue in Japanese",
        "english_translation": "The English translation",
        "questions": [
          {
            "question": "Question in English",
            "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
            "correct_index": 0,
            "explanation": "Why this is correct"
          }
        ]
      }
    PROMPT
  end

  def build_prompt(vocabulary_data)
    jlpt_level = jlpt_level_for_difficulty
    grammar_notes = grammar_notes_for_difficulty
    characters_list = format_characters_for_prompt

    <<~PROMPT
      Difficulty Level: #{@difficulty_level} (#{jlpt_level})
      WaniKani Levels: #{vocabulary_data[:min_level]}-#{vocabulary_data[:max_level]}

      Available Characters (choose EXACTLY 2):
      #{characters_list}

      Available Kanji (#{vocabulary_data[:kanji].length} randomly selected from WaniKani + Renshuu):
      #{vocabulary_data[:kanji].join(", ")}

      Available Vocabulary - WITH KANJI (#{vocabulary_data[:vocabulary].length} words from WaniKani + Renshuu + Anki):
      #{vocabulary_data[:vocabulary].join(", ")}

      Available Vocabulary - HIRAGANA ONLY (#{vocabulary_data[:hiragana_vocabulary].length} words):
      #{vocabulary_data[:hiragana_vocabulary].join(", ")}

      Grammar Guidelines: #{grammar_notes}

      IMPORTANT INSTRUCTIONS:
      1. Choose 2 characters from the list above
      2. Create a natural Japanese dialogue using ONLY the kanji and vocabulary listed above
      3. CRITICAL: Do NOT use any kanji that is not in the "Available Kanji" list or contained within the "Available Vocabulary - WITH KANJI" words
      4. CRITICAL: Do NOT use any vocabulary that is not in either vocabulary list
      5. CRITICAL: For words in "Available Vocabulary - HIRAGANA ONLY", you MUST write them in hiragana in the dialogue. Do NOT convert them to kanji. These are words where the user hasn't learned the kanji yet.
      6. The dialogue should reflect the characters' personalities, age groups, and relationship
      7. Use grammar and formality appropriate for #{jlpt_level} level and the characters' relationship
      8. Include EXACTLY 10 comprehension questions to test understanding of vocabulary, grammar, context, and inference

      VOCABULARY COMPLIANCE CHECK:
      Before finalizing your response, verify that every kanji character in your dialogue appears in either:
      - The "Available Kanji" list above, OR
      - Within one of the words in the "Available Vocabulary" list above
      If you find any kanji that doesn't meet this criteria, revise your dialogue to remove it.
    PROMPT
  end

  def jlpt_level_for_difficulty
    case @difficulty_level
    when "beginner"
      "JLPT N5"
    when "intermediate"
      "JLPT N4-N3"
    when "advanced"
      "JLPT N2-N1"
    else
      "JLPT N5"
    end
  end

  def grammar_notes_for_difficulty
    case @difficulty_level
    when "beginner"
      "Use simple present/past tense, basic particles, polite です/ます form"
    when "intermediate"
      "Use て-form, conditionals, mix of casual and polite speech"
    when "advanced"
      "Use complex grammar, honorifics, humble forms, literary expressions"
    else
      "Use simple grammar"
    end
  end

  def format_characters_for_prompt
    CHARACTERS.map do |char|
      "- #{char[:name]} (#{char[:name_romaji]}): #{char[:age_group]}, #{char[:occupation]}. #{char[:personality]}"
    end.join("\n")
  end

  def parse_and_create_dialogue(response, vocabulary_data, generation_time)
    content = extract_content(response)
    parsed = parse_json_response(content)

    dialogue = @user.dialogues.create!(
      japanese_text: parsed["japanese_text"],
      english_translation: parsed["english_translation"],
      participants: parsed["participants"] || [],
      difficulty_level: @difficulty_level,
      min_level: vocabulary_data[:min_level],
      max_level: vocabulary_data[:max_level],
      vocabulary_used: vocabulary_data[:vocabulary].first(100),
      kanji_used: vocabulary_data[:kanji].first(100),
      model_used: "openai/gpt-4o",
      generation_time_ms: generation_time
    )

    create_questions(dialogue, parsed["questions"])

    # Enqueue audio generation job asynchronously
    GenerateDialogueAudioJob.perform_later(dialogue.id)

    dialogue
  end

  def extract_content(response)
    if response.is_a?(Hash) && response["choices"]
      response["choices"].first&.dig("message", "content")
    elsif response.is_a?(String)
      response
    else
      raise GenerationError, "Unexpected response format"
    end
  end

  def parse_json_response(content)
    # Try to extract JSON from markdown code blocks if present
    json_match = content.match(/```json\s*(\{.*?\})\s*```/m) || content.match(/(\{.*\})/m)
    json_string = json_match ? json_match[1] : content

    # Sanitize the JSON string by escaping unescaped newlines within string values
    # This handles cases where the AI returns literal newlines in dialogue text
    sanitized = sanitize_json_string(json_string)

    JSON.parse(sanitized)
  rescue JSON::ParserError => e
    raise GenerationError, "Failed to parse AI response as JSON: #{e.message}\n#{json_string.truncate(500)}"
  end

  def sanitize_json_string(json_str)
    # Replace literal newlines within string values with \n
    # This is a simple approach that handles most cases
    in_string = false
    escape_next = false
    result = []

    json_str.each_char do |char|
      if escape_next
        result << char
        escape_next = false
        next
      end

      case char
      when "\\"
        escape_next = true
        result << char
      when '"'
        in_string = !in_string
        result << char
      when "\n"
        if in_string
          result << "\\n"
        else
          result << char
        end
      when "\r"
        if in_string
          result << "\\r"
        else
          result << char
        end
      when "\t"
        if in_string
          result << "\\t"
        else
          result << char
        end
      else
        result << char
      end
    end

    result.join
  end

  def create_questions(dialogue, questions_data)
    return unless questions_data.is_a?(Array)

    questions_data.each do |q|
      dialogue.comprehension_questions.create!(
        question_text: q["question"],
        options: q["options"],
        correct_option_index: q["correct_index"],
        explanation: q["explanation"]
      )
    end
  end
end
