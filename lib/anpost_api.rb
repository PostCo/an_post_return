# frozen_string_literal: true

require "faraday"
require "json"
require "net/sftp"

require_relative "anpost_api/version"

module AnpostAPI
  class Error < StandardError
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
  autoload :Configuration, "anpost_api/configuration"
  autoload :Client, "anpost_api/client"

  # Autoload resource classes
  module Resources
    autoload :Base, "anpost_api/resources/base"
    autoload :ReturnLabel, "anpost_api/resources/return_label"
    autoload :Tracking, "anpost_api/resources/tracking"
  end

  # Autoload SFTP related classes
  module SFTP
    autoload :Client, "anpost_api/sftp/client"
    autoload :Report, "anpost_api/sftp/report"
  end
end
