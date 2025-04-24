# frozen_string_literal: true

require "faraday"
require "json"
require_relative "configuration"
require_relative "errors"
require_relative "resources/return_label"

module AnPostReturn
  class Client
    attr_reader :config, :connection

    def initialize(config = Configuration.new)
      @config = config
      @config.validate!
      @connection = setup_connection
    end

    def return_labels
      @return_labels ||= Resources::ReturnLabel.new(self)
    end

    def connection
      @connection ||=
        Faraday.new(url: config.api_base_url) do |faraday|
          faraday.proxy = config.proxy_uri if config.proxy_configured?

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
      when 407
        raise ConfigurationError, "Proxy authentication required"
      else
        raise APIError, "API request failed with status #{response.status}: #{parse_error_message(response)}"
      end
    end

    def parse_error_message(response)
      return response.body["message"] if response.body.is_a?(Hash) && response.body["message"]
      return response.body["error"] if response.body.is_a?(Hash) && response.body["error"]

      "Unknown error"
    end

    def setup_connection
      Faraday.new(url: config.api_base_url) do |conn|
        conn.headers = {
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "X-API-Key" => config.api_key,
          "X-API-Secret" => config.api_secret,
        }
      end
    end
  end
end
