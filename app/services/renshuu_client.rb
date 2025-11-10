class RenshuuClient
  BASE_URL = "https://api.renshuu.org/v1"

  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end
  class RateLimitError < ApiError; end

  def initialize(api_key)
    @api_key = api_key
    ssl_verify = Rails.env.production?

    @connection = Faraday.new(url: BASE_URL, ssl: { verify: ssl_verify }) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end
  end

  def get_all_terms(term_type, page: 1)
    get("list/all/#{term_type}", { pg: page })
  end

  private

  def get(path, params = {})
    response = @connection.get(path) do |req|
      req.headers["Authorization"] = "Bearer #{@api_key}"
      req.params = params
    end

    handle_response(response)
  end

  def handle_response(response)
    case response.status
    when 200
      response.body
    when 401
      raise AuthenticationError, "Invalid API key"
    when 429
      raise RateLimitError, "Rate limit exceeded"
    else
      raise ApiError, "API request failed with status #{response.status}: #{response.body}"
    end
  end
end
