# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../instruction"

class CodeGen::Targets::Wasm::Instruction < CodeGen::Instruction
  extend T::Sig
  extend T::Helpers

  abstract!

  sig { abstract.returns(Integer) }
  def opcode; end

  sig { abstract.returns(String) }
  def wat; end
end

class CodeGen::Targets::Wasm::TypedInstruction <
  CodeGen::Targets::Wasm::Instruction

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
end

class CodeGen::Targets::Wasm::IntegerInstruction <
  CodeGen::Targets::Wasm::Instruction

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
end

class CodeGen::Targets::Wasm::FloatInstruction <
  CodeGen::Targets::Wasm::Instruction

  extend T::Sig
  extend T::Helpers

  abstract!

  include CodeGen::Targets::Wasm

  sig { returns(T.any(Type::F32, Type::F64)) }
  attr_reader :type

  sig { params(type: T.any(Type::F32, Type::F64)).void }
  def initialize(type)
    @type = type
  end
end

class CodeGen::Targets::Wasm::VariableInstruction <
  CodeGen::Targets::Wasm::Instruction

  extend T::Sig
  extend T::Helpers

  abstract!

  sig { returns(String) }
  attr_reader :variable

  sig { params(variable: String).void }
  def initialize(variable)
    @variable = variable
  end
end
