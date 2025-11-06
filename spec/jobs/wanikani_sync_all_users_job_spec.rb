require "rails_helper"

RSpec.describe WanikaniSyncAllUsersJob, type: :job do
  describe "#perform" do
    it "enqueues sync jobs for users with WaniKani API keys" do
      user_with_key = create(:user, wanikani_api_key: "test_key_1")
      user_without_key = create(:user, wanikani_api_key: nil)
      another_user_with_key = create(:user, wanikani_api_key: "test_key_2")

      allow(WanikaniSyncJob).to receive(:perform_later)

      described_class.perform_now

      expect(WanikaniSyncJob).to have_received(:perform_later).with(user_with_key.id)
      expect(WanikaniSyncJob).to have_received(:perform_later).with(another_user_with_key.id)
      expect(WanikaniSyncJob).not_to have_received(:perform_later).with(user_without_key.id)
    end

    it "logs sync activity" do
      create(:user, wanikani_api_key: "test_key")
      allow(Rails.logger).to receive(:info)
      allow(WanikaniSyncJob).to receive(:perform_later)

      described_class.perform_now

      expect(Rails.logger).to have_received(:info).with(/Starting WaniKani sync/)
      expect(Rails.logger).to have_received(:info).with("Queued WaniKani sync jobs for all users")
    end
  end
end
