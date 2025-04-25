# frozen_string_literal: true

require "faraday"
require "json"
require "net/sftp"

require_relative "an_post_return/version"

module AnPostReturn
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

  # Autoload object classes
  autoload :Base, "an_post_return/objects/base"
  autoload :ReturnLabel, "an_post_return/objects/return_label"

  # Autoload tracker
  autoload :Tracker, "an_post_return/tracker"

  # Autoload resource classes
  module Resources
    autoload :Base, "an_post_return/resources/base"
    autoload :ReturnLabelResource, "an_post_return/resources/return_label_resource"
  end

  # Autoload SFTP related classes
  module SFTP
    autoload :Client, "an_post_return/sftp/client"
    autoload :Report, "an_post_return/sftp/report"
  end
end
