require "rails_helper"

RSpec.describe RenshuuClient do
  let(:api_key) { "test_api_key_123" }
  let(:client) { described_class.new(api_key) }

  describe "#initialize" do
    it "creates a client with the provided API key" do
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
    end
  end

  describe "error handling" do
    let(:invalid_client) { described_class.new("invalid_key") }

    it "raises AuthenticationError for invalid API key" do
      expect {
        invalid_client.get_all_terms("vocab", page: 1)
      }.to raise_error(RenshuuClient::AuthenticationError)
    end
  end
end
