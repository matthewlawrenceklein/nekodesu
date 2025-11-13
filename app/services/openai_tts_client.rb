class OpenaiTtsClient
  class ApiError < StandardError; end

  BASE_URL = "https://api.openai.com/v1"

  def initialize(api_key = ENV["OPENAI_API_KEY"])
    @api_key = api_key
    @connection = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.adapter Faraday.default_adapter
      f.ssl.verify = Rails.env.production?
    end
  end

  def generate_speech(text:, voice:, model: "tts-1", response_format: "mp3", speed: 1.0)
    raise ApiError, "API key not configured" if @api_key.blank?
    raise ApiError, "Text cannot be blank" if text.blank?
    raise ApiError, "Voice cannot be blank" if voice.blank?

    response = @connection.post("audio/speech") do |req|
      req.headers["Authorization"] = "Bearer #{@api_key}"
      req.headers["Content-Type"] = "application/json"
      req.body = {
        model: model,
        input: text,
        voice: voice,
        response_format: response_format,
        speed: speed
      }
    end

    if response.success?
      response.body
    else
      # Error responses are JSON, parse them
      error_body = JSON.parse(response.body) rescue {}
      error_message = error_body.dig("error", "message") || "Unknown error"
      raise ApiError, "OpenAI TTS API error: #{error_message}"
    end
  rescue Faraday::Error => e
    raise ApiError, "OpenAI TTS connection error: #{e.message}"
  end
end
