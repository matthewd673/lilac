# typed: strict
require_relative "analysis"
require_relative "condense_labels"
require_relative "remove_useless_jumps"
require_relative "lvn"
require_relative "precompute_cond_jumps"
require_relative "remove_unused_labels"

ANALYSES = T.let([
  CondenseLabels.new,
  RemoveUselessJumps.new,
  LVN.new,
  PrecomputeCondJumps.new,
  RemoveUnusedLabels.new,
], T::Array[Analysis])
