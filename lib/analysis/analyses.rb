# typed: strict
require_relative "analysis"
require_relative "condense_labels"
require_relative "remove_useless_jumps"
require_relative "lvn"
require_relative "precompute_cond_jumps"

ANALYSES = T.let([
  CondenseLabels.new,
  RemoveUselessJumps.new,
  LVN.new,
  PrecomputeCondJumps.new,
], T::Array[Analysis])
