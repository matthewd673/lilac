# typed: strict
require "sorbet-runtime"
require_relative "../runner"
require_relative "analysis"
require_relative "analyses"

# An AnalysisRunner is a Runner for Analysis passes.
class AnalysisRunner < Runner
  extend T::Sig
  extend T::Generic

  P = type_member {{ upper: Analysis }}

  sig { params(level: Integer).returns(T::Array[Analysis]) }
  # Get all of the Analyses at a given optimization level.
  # @param [Integer] level The level to select at.
  # @return [T::Array[Analysis]] A list of Analyses.
  def level_passes(level)
    ANALYSES.select { |a| a.level == level }
  end
end
