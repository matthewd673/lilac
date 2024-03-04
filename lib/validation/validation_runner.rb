# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "../runner"

# A ValidationRunner is a Runner for Validation passes.
class Validation::ValidationRunner < Runner
  extend T::Sig
  extend T::Generic

  include Validation

  P = type_member {{ upper: ValidationPass }}
end
