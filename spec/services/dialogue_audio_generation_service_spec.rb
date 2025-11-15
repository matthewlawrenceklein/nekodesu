require "rails_helper"

RSpec.describe DialogueAudioGenerationService do
  let(:user) { create(:user) }
  let(:dialogue) do
    create(:dialogue,
      user: user,
      japanese_text: "田中さん: こんにちは\n山田くん: 元気ですか",
      participants: [ "田中さん", "山田くん" ]
    )
  end
  let(:service) { described_class.new(dialogue) }
  let(:mock_audio_data) { "fake-mp3-audio-data" }
  let(:mock_blob) { double("blob", key: "test-blob-key") }

  before do
    allow_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).and_return(mock_audio_data)
    allow(ActiveStorage::Blob).to receive(:create_and_upload!).and_return(mock_blob)
  end

  describe "#initialize" do
    it "creates a service with a dialogue" do
      expect(service.instance_variable_get(:@dialogue)).to eq(dialogue)
    end

    it "creates an OpenAI TTS client" do
      expect(service.instance_variable_get(:@tts_client)).to be_a(OpenaiTtsClient)
    end
  end

  describe "#generate" do
    it "generates audio for each dialogue line" do
      expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).twice

      service.generate
    end

    it "uses correct voice for each speaker" do
      expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).with(
        text: "こんにちは",
        voice: "echo",
        instructions: kind_of(String)
      ).and_return(mock_audio_data)

      expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).with(
        text: "元気ですか",
        voice: "onyx",
        instructions: kind_of(String)
      ).and_return(mock_audio_data)

      service.generate
    end

    it "passes character-specific instructions to TTS client" do
      expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).with(
        hash_including(
          text: "こんにちは",
          voice: "echo",
          instructions: include("Friendly, warm, approachable")
        )
      ).and_return(mock_audio_data)

      expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).with(
        hash_including(
          text: "元気ですか",
          voice: "onyx",
          instructions: include("Determined, confident, passionate")
        )
      ).and_return(mock_audio_data)

      service.generate
    end

    it "creates Active Storage blobs for audio files" do
      expect(ActiveStorage::Blob).to receive(:create_and_upload!).twice.and_return(mock_blob)

      service.generate
    end

    it "stores audio metadata in dialogue" do
      result = service.generate

      expect(result.audio_files).to be_an(Array)
      expect(result.audio_files.length).to eq(2)
      expect(result.audio_files.first).to include(
        "line_index" => 0,
        "speaker" => "田中さん",
        "text" => "こんにちは",
        "audio_key" => "test-blob-key",
        "voice" => "echo"
      )
    end

    it "returns the updated dialogue" do
      result = service.generate

      expect(result).to eq(dialogue)
      expect(result.audio_files).not_to be_empty
    end

    it "logs successful generation" do
      expect(Rails.logger).to receive(:info).with(/Generated audio for dialogue/).twice

      service.generate
    end

    context "when TTS API fails" do
      before do
        allow_any_instance_of(OpenaiTtsClient).to receive(:generate_speech)
          .and_raise(OpenaiTtsClient::ApiError.new("API error"))
      end

      it "raises GenerationError" do
        expect {
          service.generate
        }.to raise_error(DialogueAudioGenerationService::GenerationError, /Failed to generate audio/)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to generate audio/)

        begin
          service.generate
        rescue DialogueAudioGenerationService::GenerationError
          # Expected error
        end
      end
    end

    context "with dialogue containing only speaker lines" do
      let(:dialogue) do
        create(:dialogue,
          user: user,
          japanese_text: "田中さん: こんにちは\n\n山田くん: 元気ですか",
          participants: [ "田中さん", "山田くん" ]
        )
      end

      it "skips empty lines" do
        expect_any_instance_of(OpenaiTtsClient).to receive(:generate_speech).twice

        service.generate
      end
    end
  end
end
