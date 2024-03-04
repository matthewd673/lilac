# typed: strict
require "sorbet-runtime"
require_relative "../runner"
require_relative "validation"
require_relative "validations"

# A ValidationRunner is a Runner for Validation passes.
class ValidationRunner < Runner
  extend T::Sig
  extend T::Generic

  P = type_member {{ upper: Validation }}
end
