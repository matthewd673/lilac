# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

require_relative "condense_labels"
require_relative "lvn"
require_relative "const_cond_jumps"
require_relative "remove_unused_labels"
require_relative "remove_useless_jumps"
require_relative "simplify_redundant_binops"

# A definitive list of all optimizations available in Lilac.
Optimization::OPTIMIZATIONS = T.let([
  CondenseLabels.new,
  LVN.new,
  ConstCondJumps.new,
  RemoveUnusedLabels.new,
  RemoveUselessJumps.new,
  SimplifyRedundantBinops.new,
].freeze, T::Array[Optimization::OptimizationPass[T.untyped]])
