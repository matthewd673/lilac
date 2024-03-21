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
end
