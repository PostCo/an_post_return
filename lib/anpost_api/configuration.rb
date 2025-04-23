# frozen_string_literal: true

module AnpostAPI
  class Configuration
    attr_accessor :test

    def initialize
      @test = false
    end

    def api_base_url
      if test
        "https://apim-anpost-mailslabels-nonprod.dev-anpost.com/returnsapi-q/v2"
      else
        "https://apim-anpost-mailslabels.anpost.com/returnsapi/v2"
      end
    end
  end
end
