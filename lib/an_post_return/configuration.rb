# frozen_string_literal: true

module AnPostReturn
  class Configuration
    attr_accessor :test
    attr_accessor :proxy_config

    def initialize
      @test = false
      @proxy_config = nil
    end

    def api_base_url
      if test
        "https://apim-anpost-mailslabels-nonprod.dev-anpost.com/returnsapi-q/v2"
      else
        "https://apim-anpost-mailslabels.anpost.com/returnsapi/v2"
      end
    end

    def proxy_configured?
      !proxy_config.nil?
    end

    def proxy_uri
      return nil unless proxy_configured?

      uri = "http://#{proxy_config[:host]}:#{proxy_config[:port]}"
      uri = "http://#{proxy_config[:user]}:#{proxy_config[:password]}@#{proxy_config[:host]}:#{proxy_config[:port]}" if proxy_config[:user] && proxy_config[:password]
      URI.parse(uri)
    end
  end
end
