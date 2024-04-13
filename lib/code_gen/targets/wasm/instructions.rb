# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../instruction"

module CodeGen::Targets::Wasm::Instructions
  include CodeGen
  include CodeGen::Targets::Wasm

  IntegerType = T.type_alias { T.any(Type::I32, Type::I64) }

  # NUMERIC INSTRUCTIONS
  # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Numeric

  # CONSTANTS

  # Represents the +const+ instructions: +i32.const+, +i64.const+,
  # +f32.const+, and +f64.const+.
  # Declare a constant number.
  class Const < Instruction
    extend T::Sig

    include CodeGen::Targets::Wasm

    sig { returns(Type) }
    attr_reader :type
    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: Type, value: T.untyped).void }
    def initialize(type, value)
      @type = type
      @value = value
    end

    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x41
      when Type::I64 then 0x42
      when Type::F32 then 0x43
      when Type::F64 then 0x44
      end
    end
  end

  # COMPARISON

  # Represents the +eq+ instructions: +i32.eq+, +i64.eq+, +f32.eq+,
  # and +f64.eq+.
  # +eqz+ instructions are represented by +EqualZ+.
  # Check if two numbers are equal.
  class Equal < Instruction
    extend T::Sig

    include CodeGen::Targets::Wasm

    sig { returns(Type) }
    attr_reader :type

    sig { params(type: Type).void }
    def initialize(type)
      @type = type
    end

    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x46
      when Type::I64 then 0x51
      when Type::F32 then 0x5b
      when Type::F64 then 0x61
      end
    end
  end

  # Represents the +eqz+ instructions: +i32.eqz+ and +i64.eqz+.
  # Check if a number is equal to zero.
  class EqualZ < Instruction
    extend T::Sig

    include CodeGen::Targets::Wasm

    sig { returns(IntegerType) }
    attr_reader :type

    sig { params(type: IntegerType).void }
    def initialize(type)
      @type = type
    end

    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x45
      when Type::I64 then 0x50
      end
    end
  end
end
