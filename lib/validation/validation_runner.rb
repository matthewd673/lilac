# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation"
require_relative "../runner"

module Lilac
  module Validation
    # A ValidationRunner is a Runner for Validation passes.
    class ValidationRunner < Runner
      extend T::Sig
      extend T::Generic

      include Validation

      P = type_member { { fixed: ValidationPass } }

      sig { params(pass: P).void }
      # Run a ValidationPass on the program.
      def run_pass(pass)
        instance = T.unsafe(pass).new(@program)
        instance.run!
      end
    end
  end
end
