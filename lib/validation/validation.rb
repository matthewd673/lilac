# typed: strict
require "sorbet-runtime"
require_relative "../il"

class Validation
  extend T::Sig

  sig { returns(String) }
  attr_reader :id
  sig { returns(String) }
  attr_reader :description

  sig { void }
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("validation", String)
    @description = T.let("Validation stub", String)
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
