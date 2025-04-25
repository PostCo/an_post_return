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
      { "Content-Type" => "application/json", "Accept" => "application/json", "Ocp-Apim-Subscription-Key" => config.subscription_key }
    end

    def handle_response(response)
      case response.status
      when 200..299
        if response.body.is_a?(Hash) && response.body["success"] == false
          raise APIError.new(
                  "API request failed with status #{response.status}: #{parse_error_message(response)}",
                  response: response,
                )
        else
          response.body
        end
      when 400
        raise ValidationError.new(parse_error_message(response), response: response)
      when 401
        raise ConfigurationError.new("Invalid subscription key", response: response)
      when 404
        raise APIError.new("Resource not found", response: response)
      when 407
        raise ConfigurationError.new("Proxy authentication required", response: response)
      else
        raise APIError.new(
                "API request failed with status #{response.status}: #{parse_error_message(response)}",
                response: response,
              )
      end
    end

    def parse_error_message(response)
      if response.body.is_a?(Hash) && response.body["errors"]
        errors = response.body["errors"]
        if errors.is_a?(Array)
          return errors.map { |error| error["message"] }.join(", ")
        else
          return errors
        end
      end

      "Unknown error"
    end

    def setup_connection
      Faraday.new(url: config.api_base_url) do |conn|
        conn.request :json
        conn.response :json
        conn.headers = default_headers
      end
    end
  end
end
