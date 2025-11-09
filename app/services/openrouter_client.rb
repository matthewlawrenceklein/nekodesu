class OpenrouterClient
  class ApiError < StandardError; end

  def initialize(api_key)
    # SSL verification disabled in development for Docker compatibility
    # Enabled in production with proper certificate chain
    OpenRouter.configure do |config|
      config.access_token = api_key
      config.faraday do |f|
        f.ssl.verify = Rails.env.production?
      end
    end

    @client = OpenRouter::Client.new(access_token: api_key)
  end

  def chat_completion(messages:, model: "anthropic/claude-3.5-sonnet", max_tokens: 2000, temperature: 0.7)
    response = @client.complete(
      messages,
      model: model,
      extras: {
        max_tokens: max_tokens,
        temperature: temperature
      }
    )

    response
  rescue StandardError => e
    raise ApiError, "OpenRouter API error: #{e.message}"
  end
end
