# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "validation"
require_relative "../runner"

# A ValidationRunner is a Runner for Validation passes.
module Validation
  class ValidationRunner < Runner
    extend T::Sig
    extend T::Generic

    include Validation

    P = type_member { { fixed: ValidationPass } }

    sig { params(pass: P).void }
    # Run a ValidationPass on the program.
    def run_pass(pass)
      pass.run(@program)
    end
  end
end
