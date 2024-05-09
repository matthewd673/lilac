# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation"
require_relative "../pass"
require_relative "../il"

module Lilac
  module Validation
    # A ValidationPass is a Pass that performs a validation.
    class ValidationPass < Pass
      extend T::Sig
      extend T::Helpers

      abstract!

      sig { returns(String) }
      def to_s
        "#{self.class.id}: #{self.class.description}"
      end
    end
  end
end
