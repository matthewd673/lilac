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

class CodeGen::Targets::Wasm::TypedInstruction < CodeGen::Instruction
  extend T::Sig
  extend T::Helpers

  abstract!

  include CodeGen::Targets::Wasm

  sig { returns(Type) }
  attr_reader :type

  sig { params(type: Type).void }
  def initialize(type)
    @type = type
  end

  sig { abstract.returns(Integer) }
  def opcode; end
end

class CodeGen::Targets::Wasm::IntegerInstruction < CodeGen::Instruction
  extend T::Sig
  extend T::Helpers

  abstract!

  include CodeGen::Targets::Wasm

  sig { returns(T.any(Type::I32, Type::I64)) }
  attr_reader :type

  sig { params(type: T.any(Type::I32, Type::I64)).void }
  def initialize(type)
    @type = type
  end

  sig { abstract.returns(Integer) }
  def opcode; end
end
