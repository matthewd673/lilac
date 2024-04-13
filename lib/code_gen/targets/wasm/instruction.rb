# typed: strict
require "sorbet-runtime"
require_relative "code_gen"

class CodeGen::Targets::Wasm::Instruction < CodeGen::Instruction
  extend T::Sig
  extend T::Helpers

  abstract!

  sig { abstract.returns(Integer) }
  def opcode; end

end
