# frozen_string_literal: true

require_relative "base"

module AnPostReturn
  class ReturnLabel < Base
    def success?
      success
    end
  end
end
