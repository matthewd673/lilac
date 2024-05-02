# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation"
require_relative "../pass"
require_relative "../il"

module Validation
  # A ValidationPass is a Pass that performs a validation.
  class ValidationPass < Pass
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { params(program: IL::Program).void }
    def run(program)
      raise "run is unimplemented for #{id}"
    end

    sig { returns(String) }
    def to_s
      "#{id}: #{description}"
    end
  end
end
