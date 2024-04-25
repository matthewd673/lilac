# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

require_relative "tee"

include CodeGen::Targets

# A definitive list of all Wasm optimizations.
CodeGen::Targets::Wasm::Optimization::OPTIMIZATIONS = T.let([
  Wasm::Optimization::Tee.new,
], T::Array[Wasm::Optimization::OptimizationPass])
