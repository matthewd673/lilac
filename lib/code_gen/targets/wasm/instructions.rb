# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "instruction"

module CodeGen::Targets::Wasm::Instructions
  include CodeGen
  include CodeGen::Targets::Wasm

  # NUMERIC INSTRUCTIONS
  # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Numeric

  # CONSTANTS

  # Represents the +const+ instructions.
  # Declare a constant number.
  class Const < TypedInstruction
    include CodeGen::Targets::Wasm

    sig { returns(T.untyped) }
    attr_reader :value

    sig { params(type: Type, value: T.untyped).void }
    def initialize(type, value)
      super(type)

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

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.const #{@value}"
    end
  end

  # COMPARISON

  # Represents the +eq+ instructions.
  # Check if two numbers are equal.
  class Equal < TypedInstruction
    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x46
      when Type::I64 then 0x51
      when Type::F32 then 0x5b
      when Type::F64 then 0x61
      end
    end

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.eq"
    end
  end

  # Represents the +eqz+ instructions.
  # Check if a number is equal to zero.
  class EqualZero < IntegerInstruction
    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x45
      when Type::I64 then 0x50
      end
    end

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.eqz"
    end
  end

  # Represents the +ne+ instructions.
  # Check if two numbers are not equal.
  class NotEqual < TypedInstruction
    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x47
      when Type::I64 then 0x52
      when Type::F32 then 0x5c
      when Type::F64 then 0x62
      end
    end

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.ne"
    end
  end

  # TODO: GreaterThan
  # TODO: LessThan
  # TODO: GreaterOrEqual
  # TODO: LessOrEqual

  # ARITHMETIC

  # Represents the +add+ instructions.
  # Add up two numbers.
  class Add < TypedInstruction
    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x6a
      when Type::I64 then 0x7c
      when Type::F32 then 0x92
      when Type::F64 then 0xa0
      end
    end

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.add"
    end
  end

  # Represents the +sub+ instructions.
  # Subtract one number from another number.
  class Subtract < TypedInstruction
    sig { override.returns(Integer) }
    def opcode
      case @type
      when Type::I32 then 0x6b
      when Type::I64 then 0x7d
      when Type::F32 then 0x93
      when Type::F64 then 0xa1
      end
    end

    sig { override.returns(String) }
    def wat
      "#{@type.to_s}.sub"
    end
  end

  # TODO: Multiplication
  # TODO: Division
  # TODO: Remainder
end
