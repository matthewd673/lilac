# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "analysis_pass"

require_relative "condense_labels"
require_relative "remove_useless_jumps"
require_relative "lvn"
require_relative "precompute_cond_jumps"
require_relative "remove_unused_labels"
require_relative "live_vars"


# A definitive list of all analyses available in lilac.
Analysis::ANALYSES = T.let([
  CondenseLabels.new,
  RemoveUselessJumps.new,
  LVN.new,
  PrecomputeCondJumps.new,
  RemoveUnusedLabels.new,
  LiveVars.new,
], T::Array[Analysis::AnalysisPass])
