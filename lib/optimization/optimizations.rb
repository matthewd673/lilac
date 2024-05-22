# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

require_relative "lvn"
require_relative "const_cond_jumps"
require_relative "simplify_redundant_binops"
require_relative "merge_blocks"

module Lilac
  module Optimization
    # A definitive list of all optimizations available in Lilac.
    OPTIMIZATIONS = T.let([
      LVN,
      ConstCondJumps,
      SimplifyRedundantBinops,
      MergeBlocks,
    ].freeze, T::Array[T.class_of(OptimizationPass)])
  end
end
