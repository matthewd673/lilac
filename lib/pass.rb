# typed: strict
require "sorbet-runtime"
require_relative "il"

class Pass
  extend T::Sig

  sig { returns(String) }
  attr_reader :id
  sig { returns(String) }
  attr_reader :description

  sig { void }
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("pass", String)
    @description = T.let("Generic pass", String)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    raise("Run is unimplemented for #{@id}")
  end

  sig { returns(String) }
  def to_s
    "#{@id}: #{@description}"
  end
end
