# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "analysis_pass"

require_relative "live_vars"
require_relative "reaching_defs"

# A definitive list of all analyses available in Lilac.
Analysis::ANALYSES = T.let([
  LiveVars.new,
  ReachingDefs.new,
], T::Array[Analysis::AnalysisPass])
