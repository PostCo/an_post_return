# frozen_string_literal: true

module AnPostReturn
  class Configuration
    attr_accessor :test
    attr_accessor :proxy_host, :proxy_port, :proxy_username, :proxy_password

    def initialize
      @test = false
      @proxy_host = nil
      @proxy_port = nil
      @proxy_username = nil
      @proxy_password = nil
    end

    def api_base_url
      if test
        "https://apim-anpost-mailslabels-nonprod.dev-anpost.com/returnsapi-q/v2"
      else
        "https://apim-anpost-mailslabels.anpost.com/returnsapi/v2"
      end
    end

    def proxy_configured?
      !proxy_host.nil? && !proxy_port.nil?
    end

    def proxy_uri
      return nil unless proxy_configured?

      uri = "http://#{proxy_host}:#{proxy_port}"
      uri = "http://#{proxy_username}:#{proxy_password}@#{proxy_host}:#{proxy_port}" if proxy_username && proxy_password
      URI.parse(uri)
    end
  end
end
