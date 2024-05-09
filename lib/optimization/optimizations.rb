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

module Lilac
  module Optimization
    # A definitive list of all optimizations available in Lilac.
    OPTIMIZATIONS = T.let([
      CondenseLabels,
      LVN,
      ConstCondJumps,
      RemoveUnusedLabels,
      RemoveUselessJumps,
      SimplifyRedundantBinops,
    ].freeze, T::Array[T.class_of(OptimizationPass)])
  end
end
