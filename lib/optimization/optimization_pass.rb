# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "../pass"
require_relative "../il"

class Optimization::OptimizationPass < Pass
  extend T::Sig

  sig { returns(Integer) }
  attr_reader :level

  sig { void }
  def initialize
    # NOTE: these should be overwritten by subclasses
    @id = T.let("optimization", String)
    @description = T.let("Generic optimization pass", String)
    @level = T.let(-1, Integer)
  end

  sig { returns(String) }
  def to_s
    "#{@id} (#{@level}): #{@description}"
  end
end
