require "rails_helper"

RSpec.describe WanikaniSyncJob, type: :job do
  let(:user) { create(:user, wanikani_api_key: "test_api_key") }
  let(:service) { instance_double(WanikaniSyncService) }

  describe "#perform" do
    it "creates a sync service and calls sync_all" do
      allow(WanikaniSyncService).to receive(:new).with(user).and_return(service)
      allow(service).to receive(:sync_all)

      expect(WanikaniSyncService).to receive(:new).with(user)
      expect(service).to receive(:sync_all)

      described_class.perform_now(user.id)
    end

    it "logs success message" do
      allow(WanikaniSyncService).to receive(:new).with(user).and_return(service)
      allow(service).to receive(:sync_all)
      allow(Rails.logger).to receive(:info)

      described_class.perform_now(user.id)

      expect(Rails.logger).to have_received(:info)
        .with("Successfully synced WaniKani data for user #{user.id}")
    end

    context "when user does not have WaniKani configured" do
      let(:user) { create(:user, wanikani_api_key: nil) }

      it "logs warning and returns early" do
        allow(Rails.logger).to receive(:warn)

        described_class.perform_now(user.id)

        expect(Rails.logger).to have_received(:warn)
          .with("User #{user.id} does not have WaniKani configured")
      end
    end

  end
end
