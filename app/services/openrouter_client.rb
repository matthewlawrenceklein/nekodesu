class OpenrouterClient
  class ApiError < StandardError; end

  def initialize(api_key)
    @client = OpenRouter::Client.new(access_token: api_key)
  end

  def chat_completion(messages:, model: "anthropic/claude-3.5-sonnet", max_tokens: 2000, temperature: 0.7)
    response = @client.complete(
      messages: messages,
      model: model,
      max_tokens: max_tokens,
      temperature: temperature
    )

    response
  rescue StandardError => e
    raise ApiError, "OpenRouter API error: #{e.message}"
  end
end
