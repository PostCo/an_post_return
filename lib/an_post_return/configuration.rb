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

      uri = "http://#{proxy_config[:host]}:#{proxy_config[:port]}"
      uri =
        "http://#{proxy_config[:user]}:#{proxy_config[:password]}@#{proxy_config[:host]}:#{proxy_config[:port]}" if proxy_config[
        :user
      ] && proxy_config[:password]
      URI.parse(uri)
    end

    def sftp_configured?
      return false if sftp_config.nil?

      required_keys = %i[host username password remote_path]
      required_keys.all? { |key| sftp_config.key?(key) && !sftp_config[key].nil? }
    end
  end
end
