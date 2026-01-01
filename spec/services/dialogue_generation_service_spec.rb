require "rails_helper"

RSpec.describe DialogueGenerationService do
  let(:user) { create(:user, openrouter_api_key: "test_key") }
  let(:service) { described_class.new(user, difficulty_level: "beginner") }
  let(:openrouter_client) { instance_double(OpenrouterClient) }

  let(:mock_ai_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => {
              "japanese_text" => "こんにちは。元気ですか？",
              "english_translation" => "Hello. How are you?",
              "questions" => [
                {
                  "question" => "What greeting is used?",
                  "options" => [ "Hello", "Goodbye", "Thank you", "Sorry" ],
                  "correct_index" => 0,
                  "explanation" => "こんにちは means hello"
                }
              ]
            }.to_json
          }
        }
      ]
    }
  end

  before do
    allow(OpenrouterClient).to receive(:new).and_return(openrouter_client)
    allow(openrouter_client).to receive(:chat_completion).and_return(mock_ai_response)

    # Create some test vocabulary from WaniKani
    create(:wani_subject, user: user, subject_type: "kanji", characters: "元", level: 2)
    create(:wani_subject, user: user, subject_type: "kanji", characters: "気", level: 3)
    create(:wani_subject, user: user, subject_type: "vocabulary", characters: "こんにちは", level: 1)
    create(:wani_subject, user: user, subject_type: "vocabulary", characters: "元気", level: 3)

    # Create some test vocabulary from Renshuu
    create(:renshuu_item, user: user, item_type: "kanji", term: "食")
    create(:renshuu_item, user: user, item_type: "vocab", term: "食べる")
  end

  describe "#initialize" do
    it "creates an OpenRouter client" do
      expect(OpenrouterClient).to receive(:new).with("test_key")
      described_class.new(user)
    end

    it "raises error if user doesn't have API key" do
      user_without_key = create(:user, openrouter_api_key: nil)

      expect {
        described_class.new(user_without_key)
      }.to raise_error(DialogueGenerationService::GenerationError, "OpenRouter API key not configured")
    end
  end

  describe "#generate" do
    it "creates a dialogue with the AI response" do
      expect {
        service.generate
      }.to change { user.dialogues.count }.by(1)

      dialogue = user.dialogues.last
      expect(dialogue.japanese_text).to eq("こんにちは。元気ですか？")
      expect(dialogue.english_translation).to eq("Hello. How are you?")
      expect(dialogue.difficulty_level).to eq("beginner")
    end

    it "creates comprehension questions" do
      dialogue = service.generate

      expect(dialogue.comprehension_questions.count).to eq(1)
      question = dialogue.comprehension_questions.first
      expect(question.question_text).to eq("What greeting is used?")
      expect(question.options).to eq([ "Hello", "Goodbye", "Thank you", "Sorry" ])
      expect(question.correct_option_index).to eq(0)
    end

    it "records generation metadata" do
      dialogue = service.generate

      expect(dialogue.model_used).to eq("openai/gpt-4o")
      expect(dialogue.generation_time_ms).to be > 0
      expect(dialogue.min_level).to eq(1)
      expect(dialogue.max_level).to eq(10)
    end

    it "calls OpenRouter with correct parameters" do
      expect(openrouter_client).to receive(:chat_completion).with(
        hash_including(
          messages: array_including(
            hash_including(role: "system"),
            hash_including(role: "user")
          ),
          model: "openai/gpt-4o"
        )
      )

      service.generate
    end

    it "combines WaniKani and Renshuu vocabulary" do
      # Capture the prompt sent to OpenRouter
      captured_prompt = nil
      allow(openrouter_client).to receive(:chat_completion) do |args|
        captured_prompt = args[:messages].last[:content]
        mock_ai_response
      end

      service.generate

      # Should include both WaniKani and Renshuu items
      expect(captured_prompt).to include("元")  # WaniKani kanji
      expect(captured_prompt).to include("食")  # Renshuu kanji
      expect(captured_prompt).to include("こんにちは")  # WaniKani vocab
      expect(captured_prompt).to include("食べる")  # Renshuu vocab (safe - all kanji known)
    end

    it "includes hiragana vocabulary section in prompt" do
      # Capture the prompt sent to OpenRouter
      captured_prompt = nil
      allow(openrouter_client).to receive(:chat_completion) do |args|
        captured_prompt = args[:messages].last[:content]
        mock_ai_response
      end

      service.generate

      # Should have separate sections for kanji and hiragana vocabulary
      expect(captured_prompt).to include("Available Vocabulary - WITH KANJI")
      expect(captured_prompt).to include("Available Vocabulary - HIRAGANA ONLY")
    end

    context "with different difficulty levels" do
      it "uses correct level range for intermediate" do
        service = described_class.new(user, difficulty_level: "intermediate")
        dialogue = service.generate

        expect(dialogue.min_level).to eq(11)
        expect(dialogue.max_level).to eq(30)
      end

      it "uses correct level range for advanced" do
        service = described_class.new(user, difficulty_level: "advanced")
        dialogue = service.generate

        expect(dialogue.min_level).to eq(31)
        expect(dialogue.max_level).to eq(60)
      end
    end

    context "when AI response is in markdown code block" do
      let(:mock_ai_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "```json\n#{response_json}\n```"
              }
            }
          ]
        }
      end

      let(:response_json) do
        {
          "japanese_text" => "ありがとう",
          "english_translation" => "Thank you",
          "questions" => []
        }.to_json
      end

      it "extracts JSON from code block" do
        dialogue = service.generate
        expect(dialogue.japanese_text).to eq("ありがとう")
      end
    end

    context "when OpenRouter API fails" do
      before do
        allow(openrouter_client).to receive(:chat_completion)
          .and_raise(OpenrouterClient::ApiError, "API error")
      end

      it "raises GenerationError" do
        expect {
          service.generate
        }.to raise_error(DialogueGenerationService::GenerationError, /Failed to generate dialogue/)
      end
    end

    context "when AI response is invalid JSON" do
      let(:mock_ai_response) do
        {
          "choices" => [
            {
              "message" => {
                "content" => "This is not JSON"
              }
            }
          ]
        }
      end

      it "raises GenerationError" do
        expect {
          service.generate
        }.to raise_error(DialogueGenerationService::GenerationError, /Failed to parse AI response/)
      end
    end
  end
end
