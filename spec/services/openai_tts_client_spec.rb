require "rails_helper"

RSpec.describe OpenaiTtsClient do
  let(:api_key) { "test-api-key" }
  let(:client) { described_class.new(api_key) }

  describe "#initialize" do
    it "creates a client with the provided API key" do
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it "requires API key to be provided" do
      expect(client.instance_variable_get(:@api_key)).to eq(api_key)
    end

    it "creates a Faraday connection" do
      expect(client.instance_variable_get(:@connection)).to be_a(Faraday::Connection)
    end
  end

  describe "#generate_speech" do
    let(:text) { "こんにちは" }
    let(:voice) { "echo" }
    let(:audio_data) { "fake-audio-binary-data" }
    let(:mock_response) { double("response", success?: true, body: audio_data) }

    before do
      allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(mock_response)
    end

    it "generates speech successfully" do
      result = client.generate_speech(text: text, voice: voice)
      expect(result).to eq(audio_data)
    end

    it "sends correct parameters to API" do
      expect_any_instance_of(Faraday::Connection).to receive(:post).with("audio/speech").and_return(mock_response)

      client.generate_speech(text: text, voice: voice)
    end

    it "allows custom model" do
      expect_any_instance_of(Faraday::Connection).to receive(:post) do |&block|
        req = double("request", headers: {})
        allow(req).to receive(:headers=)
        expect(req).to receive(:body=).with(hash_including(model: "tts-1-hd"))
        block.call(req)
        mock_response
      end

      client.generate_speech(text: text, voice: voice, model: "tts-1-hd")
    end

    it "allows custom speed" do
      expect_any_instance_of(Faraday::Connection).to receive(:post) do |&block|
        req = double("request", headers: {})
        allow(req).to receive(:headers=)
        expect(req).to receive(:body=).with(hash_including(speed: 1.5))
        block.call(req)
        mock_response
      end

      client.generate_speech(text: text, voice: voice, speed: 1.5)
    end

    it "allows custom instructions" do
      instructions = "Voice Affect: Friendly and warm."
      expect_any_instance_of(Faraday::Connection).to receive(:post) do |&block|
        req = double("request", headers: {})
        allow(req).to receive(:headers=)
        expect(req).to receive(:body=).with(hash_including(instructions: instructions))
        block.call(req)
        mock_response
      end

      client.generate_speech(text: text, voice: voice, instructions: instructions)
    end

    it "omits instructions when not provided" do
      expect_any_instance_of(Faraday::Connection).to receive(:post) do |&block|
        req = double("request", headers: {})
        allow(req).to receive(:headers=)
        expect(req).to receive(:body=).with(hash_not_including(:instructions))
        block.call(req)
        mock_response
      end

      client.generate_speech(text: text, voice: voice)
    end

    context "error handling" do
      it "raises ApiError when API key is blank" do
        client = described_class.new("")
        expect {
          client.generate_speech(text: text, voice: voice)
        }.to raise_error(OpenaiTtsClient::ApiError, "API key not configured")
      end

      it "raises ApiError when text is blank" do
        expect {
          client.generate_speech(text: "", voice: voice)
        }.to raise_error(OpenaiTtsClient::ApiError, "Text cannot be blank")
      end

      it "raises ApiError when voice is blank" do
        expect {
          client.generate_speech(text: text, voice: "")
        }.to raise_error(OpenaiTtsClient::ApiError, "Voice cannot be blank")
      end

      it "raises ApiError on API error response" do
        error_response = double("response",
          success?: false,
          body: { "error" => { "message" => "Invalid voice parameter" } }.to_json
        )
        allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(error_response)

        expect {
          client.generate_speech(text: text, voice: "invalid")
        }.to raise_error(OpenaiTtsClient::ApiError, /Invalid voice parameter/)
      end

      it "raises ApiError on connection error" do
        allow_any_instance_of(Faraday::Connection).to receive(:post)
          .and_raise(Faraday::ConnectionFailed.new("Connection failed"))

        expect {
          client.generate_speech(text: text, voice: voice)
        }.to raise_error(OpenaiTtsClient::ApiError, /connection error/)
      end
    end
  end
end
