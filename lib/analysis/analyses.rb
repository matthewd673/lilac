# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "analysis_pass"

require_relative "live_vars"

# A definitive list of all analyses available in Lilac.
Analysis::ANALYSES = T.let([
  LiveVars.new,
], T::Array[Analysis::AnalysisPass])
