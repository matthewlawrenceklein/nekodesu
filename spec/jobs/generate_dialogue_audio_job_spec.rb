require "rails_helper"

RSpec.describe GenerateDialogueAudioJob, type: :job do
  let(:user) { create(:user) }
  let(:dialogue) do
    create(:dialogue,
      user: user,
      japanese_text: "田中さん: こんにちは\n山田くん: 元気ですか",
      participants: [ "田中さん", "山田くん" ]
    )
  end

  describe "#perform" do
    let(:mock_service) { instance_double(DialogueAudioGenerationService) }

    before do
      allow(DialogueAudioGenerationService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:generate).and_return(dialogue)
    end

    it "creates a DialogueAudioGenerationService with the dialogue" do
      expect(DialogueAudioGenerationService).to receive(:new).with(dialogue)

      described_class.perform_now(dialogue.id)
    end

    it "calls generate on the service" do
      expect(mock_service).to receive(:generate)

      described_class.perform_now(dialogue.id)
    end

    it "logs the start of generation" do
      allow(Rails.logger).to receive(:info)

      described_class.perform_now(dialogue.id)

      expect(Rails.logger).to have_received(:info).with("Generating audio for dialogue #{dialogue.id}")
    end

    it "logs successful completion" do
      allow(Rails.logger).to receive(:info)

      described_class.perform_now(dialogue.id)

      expect(Rails.logger).to have_received(:info).with("Successfully generated audio for dialogue #{dialogue.id}")
    end

    context "when generation fails" do
      before do
        allow(mock_service).to receive(:generate)
          .and_raise(DialogueAudioGenerationService::GenerationError.new("API error"))
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error and allows retry_on to handle it" do
        # The job will log the error and re-raise it for retry_on to handle
        # In test mode, perform_now may handle the retry differently
        described_class.perform_now(dialogue.id)

        expect(Rails.logger).to have_received(:error).with(/Failed to generate audio for dialogue #{dialogue.id}/)
      end
    end
  end
end
