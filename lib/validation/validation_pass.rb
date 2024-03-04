# typed: strict
require "sorbet-runtime"
require_relative "validation"
require_relative "../pass"
require_relative "../il"

class Validation::ValidationPass < Pass
  extend T::Sig

  sig { void }
  # Construct a new ValidationPass
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("validation", String)
    @description = T.let("Generic validation stub", String)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    # stub
  end

  sig { returns(String) }
  def to_s
    "#{@id}: #{@description}"
  end
end
