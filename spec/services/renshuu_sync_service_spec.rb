require "rails_helper"

RSpec.describe RenshuuSyncService do
  let(:user) { create(:user, renshuu_api_key: "test_api_key") }
  let(:service) { described_class.new(user) }
  let(:client) { instance_double(RenshuuClient) }

  before do
    allow(RenshuuClient).to receive(:new).with(user.renshuu_api_key).and_return(client)
  end

  describe "#initialize" do
    it "creates a RenshuuClient with user's API key" do
      expect(RenshuuClient).to receive(:new).with(user.renshuu_api_key)
      described_class.new(user)
    end
  end

  describe "#sync_terms_by_type" do
    let(:vocab_response) do
      {
        "contents" => {
          "result_count" => 1,
          "total_pg" => 1,
          "pg" => 1,
          "terms" => [
            {
              "id" => "1",
              "kanji_full" => "食べる",
              "hiragana_full" => "たべる",
              "def" => [ "to eat", "to consume" ],
              "markers" => [ "JLPT N5" ],
              "config" => [ "common" ],
              "user_data" => {
                "mastery_avg_perc" => "75"
              }
            }
          ]
        }
      }
    end

    it "fetches and syncs vocab terms" do
      allow(client).to receive(:get_all_terms).with("vocab", page: 1).and_return(vocab_response)

      expect {
        service.sync_terms_by_type("vocab")
      }.to change { user.renshuu_items.count }.by(1)

      item = user.renshuu_items.last
      expect(item.external_id).to eq(1)
      expect(item.item_type).to eq("vocab")
      expect(item.term).to eq("食べる")
      expect(item.reading).to eq("たべる")
      expect(item.meanings).to eq([ "to eat", "to consume" ])
      expect(item.mastery_level).to eq(75)
    end

    it "handles pagination" do
      page1_response = {
        "contents" => {
          "total_pg" => 2,
          "pg" => 1,
          "terms" => [ { "id" => "1", "kanji_full" => "食べる", "hiragana_full" => "たべる", "def" => [ "to eat" ] } ]
        }
      }
      page2_response = {
        "contents" => {
          "total_pg" => 2,
          "pg" => 2,
          "terms" => [ { "id" => "2", "kanji_full" => "飲む", "hiragana_full" => "のむ", "def" => [ "to drink" ] } ]
        }
      }

      allow(client).to receive(:get_all_terms).with("vocab", page: 1).and_return(page1_response)
      allow(client).to receive(:get_all_terms).with("vocab", page: 2).and_return(page2_response)

      expect {
        service.sync_terms_by_type("vocab")
      }.to change { user.renshuu_items.count }.by(2)
    end
  end

  describe "#sync_all" do
    before do
      allow(service).to receive(:sync_all_terms)
    end

    it "syncs all terms" do
      expect(service).to receive(:sync_all_terms)

      service.sync_all
    end

    it "updates last_renshuu_sync timestamp" do
      expect {
        service.sync_all
      }.to change { user.reload.last_renshuu_sync }.from(nil)
    end
  end
end
