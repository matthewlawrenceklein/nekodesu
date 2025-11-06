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

    it "uses updated_after parameter if last sync exists" do
      user.update!(last_wanikani_sync: 1.day.ago)
      expect(client).to receive(:get_subjects)
        .with(hash_including(:updated_after))
        .and_return(subject_response)

      service.sync_subjects
    end
  end

  describe "#sync_study_materials" do
    let!(:wani_subject) { create(:wani_subject, user: user, external_id: 1) }
    let(:material_response) do
      {
        "data" => [
          {
            "id" => 100,
            "data" => {
              "subject_id" => 1,
              "subject_type" => "kanji",
              "meaning_note" => "Test note",
              "reading_note" => "Test reading note",
              "meaning_synonyms" => [ "test" ],
              "hidden" => false,
              "created_at" => "2017-09-30T01:42:13.453291Z"
            }
          }
        ],
        "pages" => { "next_url" => nil }
      }
    end

    it "fetches and syncs study materials from WaniKani" do
      allow(client).to receive(:get_study_materials).and_return(material_response)

      expect {
        service.sync_study_materials
      }.to change { user.wani_study_materials.count }.by(1)

      material = user.wani_study_materials.last
      expect(material.external_id).to eq(100)
      expect(material.meaning_note).to eq("Test note")
      expect(material.meaning_synonyms).to eq([ "test" ])
    end

    it "skips study materials without matching subject" do
      material_response["data"][0]["data"]["subject_id"] = 999
      allow(client).to receive(:get_study_materials).and_return(material_response)

      expect {
        service.sync_study_materials
      }.not_to change { user.wani_study_materials.count }
    end
  end

  describe "#sync_all" do
    before do
      allow(service).to receive(:sync_subjects)
      allow(service).to receive(:sync_study_materials)
    end

    it "syncs subjects and study materials" do
      expect(service).to receive(:sync_subjects)
      expect(service).to receive(:sync_study_materials)

      service.sync_all
    end

    it "updates last_wanikani_sync timestamp" do
      expect {
        service.sync_all
      }.to change { user.reload.last_wanikani_sync }.from(nil)
    end
  end
end
