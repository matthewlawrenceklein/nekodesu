require "rails_helper"

RSpec.describe WanikaniSyncService do
  let(:user) { create(:user, wanikani_api_key: "test_api_key") }
  let(:service) { described_class.new(user) }
  let(:client) { instance_double(WanikaniClient) }

  before do
    allow(WanikaniClient).to receive(:new).with(user.wanikani_api_key).and_return(client)
  end

  describe "#initialize" do
    it "creates a WanikaniClient with user's API key" do
      expect(WanikaniClient).to receive(:new).with(user.wanikani_api_key)
      described_class.new(user)
    end
  end

  describe "#sync_subjects" do
    let(:subject_response) do
      {
        "data" => [
          {
            "id" => 1,
            "object" => "kanji",
            "data" => {
              "characters" => "一",
              "slug" => "one",
              "level" => 1,
              "lesson_position" => 1,
              "meaning_mnemonic" => "Test mnemonic",
              "reading_mnemonic" => "Test reading",
              "document_url" => "https://www.wanikani.com/kanji/one",
              "meanings" => [ { "meaning" => "One", "primary" => true } ],
              "auxiliary_meanings" => [],
              "readings" => [ { "reading" => "いち", "primary" => true } ],
              "component_subject_ids" => [],
              "hidden_at" => nil,
              "created_at" => "2012-02-27T19:55:19.000000Z"
            }
          }
        ],
        "pages" => { "next_url" => nil }
      }
    end

    before do
      user.update!(level: 5)
    end

    it "fetches and syncs subjects from WaniKani" do
      allow(client).to receive(:get_subjects).and_return(subject_response)

      expect {
        service.sync_subjects
      }.to change { user.wani_subjects.count }.by(1)

      subject = user.wani_subjects.last
      expect(subject.external_id).to eq(1)
      expect(subject.subject_type).to eq("kanji")
      expect(subject.characters).to eq("一")
    end

    it "syncs subjects from levels 1 to (current_level - 1)" do
      user.update!(level: 10)
      expect(client).to receive(:get_subjects)
        .with(hash_including(levels: "1,2,3,4,5,6,7,8,9"))
        .and_return(subject_response)

      service.sync_subjects
    end

    it "syncs at least level 1 when user is at level 1" do
      user.update!(level: 1)
      expect(client).to receive(:get_subjects)
        .with(hash_including(levels: "1"))
        .and_return(subject_response)

      service.sync_subjects
    end

    it "uses updated_after parameter if last sync exists" do
      user.update!(last_wanikani_sync: 1.day.ago)
      expect(client).to receive(:get_subjects)
        .with(hash_including(:updated_after))
        .and_return(subject_response)

      service.sync_subjects
    end
  end

  describe "#sync_user_info" do
    let(:user_response) do
      {
        "data" => {
          "level" => 5,
          "username" => "testuser"
        }
      }
    end

    it "fetches and updates user level" do
      allow(client).to receive(:get_user).and_return(user_response)

      expect {
        service.sync_user_info
      }.to change { user.reload.level }.to(5)
    end
  end

  describe "#sync_all" do
    before do
      allow(service).to receive(:sync_user_info)
      allow(service).to receive(:sync_subjects)
    end

    it "syncs user info and subjects" do
      expect(service).to receive(:sync_user_info)
      expect(service).to receive(:sync_subjects)

      service.sync_all
    end

    it "updates last_wanikani_sync timestamp" do
      expect {
        service.sync_all
      }.to change { user.reload.last_wanikani_sync }.from(nil)
    end
  end
end
