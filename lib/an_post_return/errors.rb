module AnPostReturn
  class ParserError < StandardError
  end
  class Error < StandardError
    attr_reader :response

    def initialize(message, response: nil)
      @response = response
      super(message)
    end
  end

  class ConfigurationError < Error
  end

  class APIError < Error
  end

  class ValidationError < Error
  end
end
