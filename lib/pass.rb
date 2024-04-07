# typed: strict
require "sorbet-runtime"
require_relative "il"

# A Pass represents a process that can be run on a Program.
# Some passes may modify a Program in place.
# Passes should be created once and then reused.
class Pass
  extend T::Sig

  sig { returns(String) }
  attr_reader :id
  sig { returns(String) }
  attr_reader :description

  sig { void }
  # Construct a new Pass.
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("pass", String)
    @description = T.let("Generic pass", String)
  end

  sig { returns(String) }
  def to_s
    "#{@id}: #{@description}"
  end
end
