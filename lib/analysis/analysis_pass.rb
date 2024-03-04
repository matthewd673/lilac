# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "../pass"
require_relative "../il"

class Analysis::AnalysisPass < Pass
  extend T::Sig

  sig { returns(Integer) }
  attr_reader :level

  sig { void }
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("analysis", String)
    @description = T.let("Generic analysis pass", String)
    @level = T.let(1, Integer)
  end

  sig { returns(String) }
  def to_s
    "#{@id} (#{@level}): #{@description}"
  end
end
