# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "../runner"
require_relative "analysis_pass"

# An AnalysisRunner is a Runner for Analysis passes.
class Analysis::AnalysisRunner < Runner
  extend T::Sig
  extend T::Generic

  include Analysis

  P = type_member {{ upper: AnalysisPass }}

  sig { params(level: Integer).returns(T::Array[AnalysisPass]) }
  # Get all of the Analyses at a given optimization level.
  # @param [Integer] level The level to select at.
  # @return [T::Array[AnalysisPass]] A list of Analyses.
  def level_passes(level)
    ANALYSES.select { |a| a.level == level }
  end
end
