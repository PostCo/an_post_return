# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/string"
require "active_support/hash_with_indifferent_access"
require "ostruct"

module AnPostReturn
  class Base < OpenStruct
    attr_reader :original_response

    def initialize(attributes)
      @original_response = attributes
      super to_ostruct(attributes)
    end

    def to_ostruct(obj)
      if obj.is_a?(Hash)
        OpenStruct.new(obj.map { |key, val| [key.to_s.underscore, to_ostruct(val)] }.to_h)
      elsif obj.is_a?(Array)
        obj.map { |o| to_ostruct(o) }
      else # Assumed to be a primitive value
        obj
      end
    end

    # Return the original response with camelCase keys preserved
    def response
      @original_response
    end

    # Convert back to hash without table key, including nested structures
    def to_hash
      ostruct_to_hash(self)
    end

    # Override comparison to handle hash comparison
    def ==(other)
      case other
      when Hash
        to_hash == other
      else
        super
      end
    end

    # Override eql? to be consistent with ==
    def eql?(other)
      self == other
    end

    private

    def ostruct_to_hash(object)
      case object
      when OpenStruct
        hash = object.to_h.reject { |k, _| k == :table }
        # Convert to HashWithIndifferentAccess and process values recursively
        ActiveSupport::HashWithIndifferentAccess.new(hash).transform_values { |value| ostruct_to_hash(value) }
      when Array
        object.map { |item| ostruct_to_hash(item) }
      when Hash
        # Convert to HashWithIndifferentAccess and process values recursively
        ActiveSupport::HashWithIndifferentAccess.new(object).transform_values { |value| ostruct_to_hash(value) }
      else
        object
      end
    end
  end
end
