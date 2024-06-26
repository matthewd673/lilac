# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../runner"

module Lilac
  module Validation
    # A ValidationRunner is a Runner for Validation passes.
    class ValidationRunner < Runner
      extend T::Sig
      extend T::Generic

      include Validation

      U = type_member { { fixed: IL::Program } }
      P = type_member { { fixed: T.class_of(ValidationPass) } }

      sig { params(pass: P).void }
      # Run a ValidationPass on the program.
      def run_pass(pass)
        instance = T.unsafe(pass).new(@program)
        instance.run!
      end
    end
  end
end
