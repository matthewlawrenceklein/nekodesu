require "rails_helper"

RSpec.describe GenerateDialoguesJob, type: :job do
  let(:user) { create(:user, openrouter_api_key: "test_key") }
  let(:service) { instance_double(DialogueGenerationService) }
  let(:dialogue) { create(:dialogue, user: user) }

  before do
    allow(DialogueGenerationService).to receive(:new).and_return(service)
    allow(service).to receive(:generate).and_return(dialogue)
  end

  describe "#perform" do
    it "generates the specified number of dialogues" do
      expect(DialogueGenerationService).to receive(:new)
        .with(user, difficulty_level: "beginner")
        .exactly(5).times

      expect(service).to receive(:generate).exactly(5).times

      described_class.perform_now(user.id, count: 5, difficulty_level: "beginner")
    end

    it "uses default count of 10" do
      expect(service).to receive(:generate).exactly(10).times

      described_class.perform_now(user.id)
    end

    it "uses default difficulty of beginner" do
      expect(DialogueGenerationService).to receive(:new)
        .with(user, difficulty_level: "beginner")

      described_class.perform_now(user.id, count: 1)
    end

    it "allows custom difficulty level" do
      expect(DialogueGenerationService).to receive(:new)
        .with(user, difficulty_level: "advanced")

      described_class.perform_now(user.id, count: 1, difficulty_level: "advanced")
    end

    it "logs successful generation" do
      allow(Rails.logger).to receive(:info)

      described_class.perform_now(user.id, count: 2)

      expect(Rails.logger).to have_received(:info)
        .with(/Generating 2 beginner dialogues/)
      expect(Rails.logger).to have_received(:info)
        .with(/Completed dialogue generation.*2 successful, 0 failed/)
    end

    context "when user does not have OpenRouter configured" do
      let(:user) { create(:user, openrouter_api_key: nil) }

      it "logs warning and returns early" do
        allow(Rails.logger).to receive(:warn)

        described_class.perform_now(user.id, count: 5)

        expect(Rails.logger).to have_received(:warn)
          .with("User #{user.id} does not have OpenRouter configured")
        expect(service).not_to have_received(:generate)
      end
    end

    context "when generation fails" do
      before do
        allow(service).to receive(:generate)
          .and_raise(DialogueGenerationService::GenerationError, "API error")
      end

      it "logs error and continues" do
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)

        described_class.perform_now(user.id, count: 2)

        expect(Rails.logger).to have_received(:error)
          .with(/Failed to generate dialogue.*API error/)
          .twice
        expect(Rails.logger).to have_received(:info)
          .with(/0 successful, 2 failed/)
      end
    end

    context "when some generations succeed and some fail" do
      before do
        call_count = 0
        allow(service).to receive(:generate) do
          call_count += 1
          if call_count.odd?
            dialogue
          else
            raise DialogueGenerationService::GenerationError, "API error"
          end
        end
      end

      it "tracks both successful and failed generations" do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:error)

        described_class.perform_now(user.id, count: 4)

        expect(Rails.logger).to have_received(:info)
          .with(/2 successful, 2 failed/)
      end
    end
  end
end
