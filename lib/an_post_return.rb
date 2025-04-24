# frozen_string_literal: true

require "faraday"
require "json"
require "net/sftp"

require_relative "an_post_return/version"

module AnPostReturn
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

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset
      @configuration = Configuration.new
    end
  end

  # Autoload core classes
  autoload :Configuration, "an_post_return/configuration"
  autoload :Client, "an_post_return/client"

  # Autoload resource classes
  module Resources
    autoload :Base, "an_post_return/resources/base"
    autoload :ReturnLabel, "an_post_return/resources/return_label"
    autoload :Tracking, "an_post_return/resources/tracking"
  end

  # Autoload SFTP related classes
  module SFTP
    autoload :Client, "an_post_return/sftp/client"
    autoload :Report, "an_post_return/sftp/report"
  end
end
