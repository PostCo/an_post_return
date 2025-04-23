# frozen_string_literal: true

module AnpostAPI
  class Client
    attr_reader :config

    def initialize(config = AnpostAPI.configuration)
      @config = config
    end

    def connection
      @connection ||=
        Faraday.new(url: config.api_base_url) do |faraday|
          faraday.request :json
          faraday.response :json
          faraday.adapter Faraday.default_adapter
          faraday.headers = default_headers
        end
    end

    private

    def default_headers
      { "Content-Type" => "application/json", "Accept" => "application/json" }
    end

    def handle_response(response)
      case response.status
      when 200..299
        response.body
      when 400
        raise ValidationError, parse_error_message(response)
      when 401
        raise ConfigurationError, "Invalid subscription key"
      when 404
        raise APIError, "Resource not found"
      else
        raise APIError, "API request failed with status #{response.status}: #{parse_error_message(response)}"
      end
    end

    def parse_error_message(response)
      return response.body["message"] if response.body.is_a?(Hash) && response.body["message"]
      return response.body["error"] if response.body.is_a?(Hash) && response.body["error"]

      "Unknown error"
    end
  end
end
