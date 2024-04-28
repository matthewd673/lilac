# typed: strict
require "sorbet-runtime"
require_relative "../wasm"
require_relative "../../../instruction"

module CodeGen::Targets::Wasm::Instructions
  extend T::Sig

  include CodeGen
  include CodeGen::Targets::Wasm

  # HELPER FUNCTIONS
  sig { params(il_type: IL::Type).returns(Type) }
  def self.to_wasm_type(il_type)
    case il_type
    when IL::Type::I32 then Type::I32
    when IL::Type::I64 then Type::I64
    when IL::Type::F32 then Type::F32
    when IL::Type::F64 then Type::F64
    else
      raise "IL type #{il_type} is not supported by Wasm"
    end
  end

  sig { params(il_type: IL::Type).returns(IntegerType) }
  def self.to_integer_type(il_type)
    case il_type
    when IL::Type::I32 then Type::I32
    when IL::Type::I64 then Type::I64
    else
      raise "IL type #{il_type} is not an integer type or not supported by Wasm"
    end
  end

  sig { params(il_type: IL::Type).returns(FloatType) }
  def self.to_float_type(il_type)
    case il_type
    when IL::Type::F32 then Type::F32
    when IL::Type::F64 then Type::F64
    else
      raise "IL type #{il_type} is not an integer type or not supported by Wasm"
    end
  end

  # INSTRUCTION CLASSES

  class WasmInstruction < CodeGen::Instruction
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { abstract.returns(Integer) }
    def opcode; end

    sig { abstract.returns(String) }
    def wat; end
  end

  class TypedInstruction < WasmInstruction
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

  class IntegerInstruction < WasmInstruction
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

  class FloatInstruction < WasmInstruction
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

  class VariableInstruction < WasmInstruction
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

  class LabelInstruction < WasmInstruction
    extend T::Sig
    extend T::Helpers

    abstract!

    sig { returns(String) }
    attr_reader :label

    sig { params(label: String).void }
    def initialize(label)
      @label = label
    end
  end
end
