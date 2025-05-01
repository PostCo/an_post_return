# frozen_string_literal: true

module AnPostReturn
  class Configuration
    attr_accessor :test
    attr_accessor :proxy_config
    attr_accessor :sftp_config
    attr_accessor :subscription_key

    def initialize
      @test = false
      @proxy_config = nil
      @sftp_config = nil
      @subscription_key = nil
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

      user = proxy_config[:user]
      password = proxy_config[:password]
      host = proxy_config[:host]
      port = proxy_config[:port]

      uri_string = "http://#{host}:#{port}"
      if user && password
        encoded_user = URI.encode_www_form_component(user)
        encoded_password = URI.encode_www_form_component(password)
        uri_string = "http://#{encoded_user}:#{encoded_password}@#{host}:#{port}"
      end

      URI.parse(uri_string)
    end

    def sftp_configured?
      return false if sftp_config.nil?

      required_keys = %i[host username password remote_path]
      required_keys.all? { |key| sftp_config.key?(key) && !sftp_config[key].nil? }
    end
  end
end
