# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "../../../../../pass"
require_relative "../instructions/instructions"

class CodeGen::Targets::Wasm::Optimization::OptimizationPass < Pass
  extend T::Sig
  extend T::Helpers

  include CodeGen::Targets::Wasm

  abstract!

  sig { abstract.returns(String) }
  def id; end

  sig { abstract.returns(String) }
  def description; end

  sig { abstract.params(instructions: T::Array[Instructions::WasmInstruction])
          .void }
  def run(instructions); end

end
