# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

require_relative "condense_labels"
require_relative "lvn"
require_relative "precompute_cond_jumps"
require_relative "remove_unused_labels"
require_relative "remove_useless_jumps"

# A definitive list of all optimizations available in Lilac.
Optimization::OPTIMIZATIONS = T.let([
  CondenseLabels.new,
  LVN.new,
  PrecomputeCondJumps.new,
  RemoveUnusedLabels.new,
  RemoveUselessJumps.new,
], T::Array[Optimization::OptimizationPass])
