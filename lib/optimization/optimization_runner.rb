# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimizations"
require_relative "optimization_pass"
require_relative "../runner"

# An OptimizationRunner is a Runner for Optimization passes.
class Optimization::OptimizationRunner < Runner
  extend T::Sig
  extend T::Generic

  include Optimization

  P = type_member {{ upper: OptimizationPass }}

  sig { params(level: Integer).returns(T::Array[OptimizationPass]) }
  # Get all of the Optimizations at a given optimization level.
  # @param [Integer] level The level to select at.
  # @return [T::Array[OptimizationPass]] A list of Optimizations.
  def level_passes(level)
    OPTIMIZATIONS.select { |o| o.level == level }
  end
end
