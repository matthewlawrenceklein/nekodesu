class DialogueGenerationService
  class GenerationError < StandardError; end

  def initialize(user, difficulty_level: "beginner")
    @user = user
    @difficulty_level = difficulty_level
    @openrouter_client = OpenrouterClient.new(user.openrouter_api_key || ENV["OPENROUTER_API_KEY"])
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
      model: "anthropic/claude-3.5-sonnet",
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
    subjects = @user.wani_subjects
                    .visible
                    .where(level: level_range)
                    .order(:level)

    {
      kanji: subjects.kanji.pluck(:characters).compact,
      vocabulary: subjects.vocabulary.pluck(:characters).compact,
      min_level: level_range.min,
      max_level: level_range.max
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

      Requirements:
      1. Use ONLY the kanji and vocabulary words provided
      2. Create a natural, conversational dialogue
      3. Match the grammar complexity and formality to the difficulty level:
         - Beginner (N5): Simple present/past tense, basic particles (は、が、を、に、で), polite form (です/ます)
         - Intermediate (N4-N3): More complex particles, て-form, conditionals, casual and polite forms
         - Advanced (N2-N1): Complex grammar, honorifics/humble forms, nuanced expressions, literary style
      4. Include 2-3 comprehension questions with 4 multiple choice options each
      5. Provide English translations

      Format your response as JSON with this structure:
      {
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

    <<~PROMPT
      Difficulty Level: #{@difficulty_level} (#{jlpt_level})
      WaniKani Levels: #{vocabulary_data[:min_level]}-#{vocabulary_data[:max_level]}

      Available Kanji (#{vocabulary_data[:kanji].length}):
      #{vocabulary_data[:kanji].first(100).join(", ")}

      Available Vocabulary (#{vocabulary_data[:vocabulary].length}):
      #{vocabulary_data[:vocabulary].first(100).join(", ")}

      Grammar Guidelines: #{grammar_notes}

      Please create a natural Japanese dialogue using ONLY these kanji and vocabulary words.
      Use grammar and formality appropriate for #{jlpt_level} level.
      Include 2-3 comprehension questions to test understanding.
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

  def parse_and_create_dialogue(response, vocabulary_data, generation_time)
    content = extract_content(response)
    parsed = parse_json_response(content)

    dialogue = @user.dialogues.create!(
      japanese_text: parsed["japanese_text"],
      english_translation: parsed["english_translation"],
      difficulty_level: @difficulty_level,
      min_level: vocabulary_data[:min_level],
      max_level: vocabulary_data[:max_level],
      vocabulary_used: vocabulary_data[:vocabulary].first(100),
      kanji_used: vocabulary_data[:kanji].first(100),
      model_used: "anthropic/claude-3.5-sonnet",
      generation_time_ms: generation_time
    )

    create_questions(dialogue, parsed["questions"])

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

    JSON.parse(json_string)
  rescue JSON::ParserError => e
    raise GenerationError, "Failed to parse AI response as JSON: #{e.message}"
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
