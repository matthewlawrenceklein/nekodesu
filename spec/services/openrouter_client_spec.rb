require "rails_helper"

RSpec.describe OpenrouterClient do
  let(:api_key) { "test_api_key" }
  let(:client) { described_class.new(api_key) }

  describe "#initialize" do
    it "creates an OpenRouter client" do
      expect(client.instance_variable_get(:@client)).to be_a(OpenRouter::Client)
    end
  end

  describe "#chat_completion" do
    let(:messages) { [ { role: "user", content: "Hello" } ] }
    let(:mock_response) do
      {
        "id" => "gen-123",
        "model" => "anthropic/claude-3.5-sonnet",
        "choices" => [
          {
            "message" => {
              "role" => "assistant",
              "content" => "Hello! How can I help you?"
            }
          }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenRouter::Client).to receive(:complete).and_return(mock_response)
    end

    it "calls the OpenRouter client with correct parameters" do
      expect_any_instance_of(OpenRouter::Client).to receive(:complete).with(
        messages,
        model: "openai/gpt-4o",
        extras: {
          max_tokens: 2000,
          temperature: 0.7
        }
      )

      client.chat_completion(messages: messages)
    end

    it "returns the response from OpenRouter" do
      result = client.chat_completion(messages: messages)

      expect(result).to eq(mock_response)
    end

    it "allows custom model" do
      expect_any_instance_of(OpenRouter::Client).to receive(:complete).with(
        messages,
        hash_including(model: "openai/gpt-4")
      )

      client.chat_completion(messages: messages, model: "openai/gpt-4")
    end

    it "allows custom max_tokens" do
      expect_any_instance_of(OpenRouter::Client).to receive(:complete).with(
        messages,
        hash_including(extras: hash_including(max_tokens: 1000))
      )

      client.chat_completion(messages: messages, max_tokens: 1000)
    end

    it "allows custom temperature" do
      expect_any_instance_of(OpenRouter::Client).to receive(:complete).with(
        messages,
        hash_including(extras: hash_including(temperature: 0.5))
      )

      client.chat_completion(messages: messages, temperature: 0.5)
    end
  end

  describe "error handling" do
    let(:messages) { [ { role: "user", content: "Hello" } ] }

    it "wraps OpenRouter errors in ApiError" do
      allow_any_instance_of(OpenRouter::Client).to receive(:complete)
        .and_raise(StandardError.new("Connection failed"))

      expect {
        client.chat_completion(messages: messages)
      }.to raise_error(OpenrouterClient::ApiError, /OpenRouter API error: Connection failed/)
    end
  end
end
