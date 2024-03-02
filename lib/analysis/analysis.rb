# typed: strict
require "sorbet-runtime"
require_relative "../il"

class Analysis
  extend T::Sig

  sig { returns(String) }
  attr_reader :id
  sig { returns(String) }
  attr_reader :description
  sig { returns(Integer) }
  attr_reader :level

  sig { void }
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("analysis", String)
    @description = T.let("Analysis stub", String)
    @level = T.let(1, Integer)
  end

  sig { params(program: IL::Program).void }
  def run(program)
    # stub
  end

  sig { returns(String) }
  def to_s
    "#{@id} (#{@level}): #{@description}"
  end
end
