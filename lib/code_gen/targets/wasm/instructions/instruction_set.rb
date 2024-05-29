# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "instructions"
require_relative "../../../../il"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # The Instructions module defines base classes that describe broad
        # groups of Wasm instructions. It also aims to contain the entire Wasm
        # instruction set.
        module Instructions
          extend T::Sig
          # NUMERIC INSTRUCTIONS
          # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Numeric

          # CONSTANTS

          # Represents the +i32.const+ and +i64.const+ instructions.
          # Declare a constant integer number.
          class ConstInteger < IntegerInstruction
            include CodeGen::Targets::Wasm

            sig { returns(String) }
            attr_reader :value

            sig do
              params(type: T.any(Type::I32, Type::I64), value: String).void
            end
            def initialize(type, value)
              super(type)

              @value = value
            end

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x41
              when Type::I64 then 0x42
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.const #{@value}"
            end
          end

          # Represents the +f32.const+ and +f64.const+ instructions.
          # Declare a constant integer number.
          class ConstFloat < FloatInstruction
            include CodeGen::Targets::Wasm

            sig { returns(String) }
            attr_reader :value

            sig do
              params(type: T.any(Type::F32, Type::F64), value: String).void
            end
            def initialize(type, value)
              super(type)

              @value = value
            end

            sig { override.returns(Integer) }
            def opcode
              case @type
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

          # Represents the +gt_s+ instructions.
          # Check if a number is greater than another number
          # (signed integers only).
          class GreaterThanSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4a
              when Type::I64 then 0x55
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.gt_s"
            end
          end

          # Represents the +gt_u+ instructions.
          # Check if a number is greater than another number
          # (unsigned integers only).
          class GreaterThanUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4b
              when Type::I64 then 0x56
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.gt_u"
            end
          end

          # Represents the +gt+ instructions.
          # Check if a number is greater than another number
          # (floating point only).
          class GreaterThan < FloatInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::F32 then 0x5e
              when Type::F64 then 0x64
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.gt"
            end
          end

          # Represents the +lt_s+ instructions.
          # Check if a number is less than another number
          # (signed integers only).
          class LessThanSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x48
              when Type::I64 then 0x53
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.lt_s"
            end
          end

          # Represents the +lt_u+ instructions.
          # Check if a number is less than another number
          # (unsigned integers only).
          class LessThanUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x49
              when Type::I64 then 0x54
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.lt_u"
            end
          end

          # Represents the +lt+ instructions.
          # Check if a number is less than another number (floating point only).
          class LessThan < FloatInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::F32 then 0x5d
              when Type::F64 then 0x63
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.lt"
            end
          end

          # Represents the +ge_s+ instructions.
          # Check if a number is greater than or equal to another number (signed
          # integers only).
          class GreaterOrEqualSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4e
              when Type::I64 then 0x59
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.ge_s"
            end
          end

          # Represents the +ge_u+ instructions.
          # Check if a number is greater than or equal to another number
          # (unsigned integers only).
          class GreaterOrEqualUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4f
              when Type::I64 then 0x5a
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.ge_u"
            end
          end

          # Represents the +ge+ instructions.
          # Check if a number is greater than or equal to another number
          # (floating point only).
          class GreaterOrEqual < FloatInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::F32 then 0x60
              when Type::F64 then 0x66
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.ge"
            end
          end

          # Represents the +le_s+ instructions.
          # Check if a number is less than or equal to another number (signed
          # integers only).
          class LessOrEqualSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4c
              when Type::I64 then 0x57
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.le_s"
            end
          end

          # Represents the +le_u+ instructions.
          # Check if a number is less than or equal to another number (unsigned
          # integers only).
          class LessOrEqualUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x4d
              when Type::I64 then 0x58
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.le_u"
            end
          end

          # Represents the +le+ instructions.
          # Check if a number is less than or equal to another number (floating
          # point only).
          class LessOrEqual < FloatInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::F32 then 0x5f
              when Type::F64 then 0x65
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.le"
            end
          end

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

          # Represents the +mul+ instructions.
          # Multiply one number by another number.
          class Multiply < TypedInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x6c
              when Type::I64 then 0x7e
              when Type::F32 then 0x94
              when Type::F64 then 0xa2
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.mul"
            end
          end

          # Represents the +div_s+ instructions.
          # Divide one number by another number (signed integers only).
          class DivideSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x6d
              when Type::I64 then 0x7f
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.div_s"
            end
          end

          # Represents the +div_u+ instructions.
          # Divide one number by another number (unsiged integers only).
          class DivideUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x6e
              when Type::I64 then 0x80
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.div_u"
            end
          end

          # Represents the +div+ instructions.
          # Divide one number by another number (floating point only).
          class Divide < FloatInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::F32 then 0x95
              when Type::F64 then 0xa3
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.div"
            end
          end

          # Represents the +rem_s+ instructions.
          # Calculate the remainder left over when one integer is divided by
          # another integer (signed integers only).
          class RemainderSigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x6f
              when Type::I64 then 0x81
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.rem_s"
            end
          end

          # Represents the +rem_u+ instructions.
          # Calculate the remainder left over when one integer is divided by
          # another integer (unsigned integers only).
          class RemainderUnsigned < IntegerInstruction
            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x70
              when Type::I64 then 0x82
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type.to_s}.rem_u"
            end
          end

          # VARIABLE INSTRUCTIONS
          # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Variables

          # Represents the +local.get+ instruction.
          # Load the value of a local variable onto the stack.
          class LocalGet < VariableInstruction
            sig { override.returns(Integer) }
            def opcode
              0x20
            end

            sig { override.returns(String) }
            def wat
              "local.get $#{@variable}"
            end
          end

          # Represents the +local.set+ instruction.
          # Set the value of a local variable.
          class LocalSet < VariableInstruction
            sig { override.returns(Integer) }
            def opcode
              0x21
            end

            sig { override.returns(String) }
            def wat
              "local.set $#{@variable}"
            end
          end

          # Represents the +local.tee+ instruction.
          # Set the value of a local variable and keep the value on the stack.
          class LocalTee < VariableInstruction
            sig { override.returns(Integer) }
            def opcode
              0x22
            end

            sig { override.returns(String) }
            def wat
              "local.tee $#{@variable}"
            end
          end

          # Represents the +global.get+ instruction.
          # Load the value of a global variable onto the stack.
          class GlobalGet < VariableInstruction
            sig { override.returns(Integer) }
            def opcode
              0x23
            end

            sig { override.returns(String) }
            def wat
              "global.get $#{@variable}"
            end
          end

          # Represents the +global.set+ instruction
          # Set the value of a global variable.
          class GlobalSet < VariableInstruction
            sig { override.returns(Integer) }
            def opcode
              0x24
            end

            sig { override.returns(String) }
            def wat
              "global.set $#{@variable}"
            end
          end

          # MEMORY INSTRUCTIONS
          # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Memory

          # Represents the +memory.grow+ instruction.
          # Increase the size of a memory by some number of pages.
          class Grow < MemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x40
            end

            sig { override.returns(String) }
            def wat
              "memory.grow#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +memory.size+ instruction.
          # Get the number of pages in a memory.
          class Size < MemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x3f
            end

            sig { override.returns(String) }
            def wat
              "memory.size#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +load+ instructions.
          # Load a number from a memory.
          class Load < TypedMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x28
              when Type::I64 then 0x29
              when Type::F32 then 0x2a
              when Type::F64 then 0x2b
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.load#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +load8_s+ instructions.
          class Load8S < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x2c
              when Type::I64 then 0x30
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.load8_s#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +load8_u+ instructions.
          class Load8U < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x2d
              when Type::I64 then 0x31
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.load8_u#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +load16_s+ instructions.
          class Load16S < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x2c
              when Type::I64 then 0x32
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.load16_s#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +load16_u+ instructions.
          class Load16U < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x2f
              when Type::I64 then 0x33
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.load16_u#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +i64.load32_s+ instruction.
          class Load32S < MemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x34
            end

            sig { override.returns(String) }
            def wat
              "i64.load32_s#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +i64.load32_u+ instruction.
          class Load32U < MemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x35
            end

            sig { override.returns(String) }
            def wat
              "i64.load32_u#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +store+ instructions.
          # Store a number at an offset in a memory.
          class Store < TypedMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x36
              when Type::I64 then 0x37
              when Type::F32 then 0x38
              when Type::F64 then 0x39
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.store#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +store8+ instructions.
          class Store8 < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x3a
              when Type::I64 then 0x3c
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.store8#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +store16+ instructions.
          class Store16 < IntegerMemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              case @type
              when Type::I32 then 0x3b
              when Type::I64 then 0x3d
              end
            end

            sig { override.returns(String) }
            def wat
              "#{@type}.store16#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # Represents the +i64.store32+ instruction.
          class Store32 < MemoryInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x3e
            end

            sig { override.returns(String) }
            def wat
              "i64.store32#{@memory ? " (memory $#{@memory})" : ""}"
            end
          end

          # TODO: copy
          # TODO: fill

          # CONTROL FLOW INSTRUCTIONS
          # https://developer.mozilla.org/en-US/docs/WebAssembly/Reference/Control_flow

          # Represents the +block+ instruction.
          # Create a label that can be branched out of.
          class Block < LabelInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x02
            end

            sig { override.returns(String) }
            def wat
              "block $#{@label}"
            end
          end

          # Represents the +br+ instruction.
          # Branch to a loop or block.
          class Branch < LabelInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x0c
            end

            sig { override.returns(String) }
            def wat
              "br $#{@label}"
            end
          end

          # Represents the +br_if+ instruction.
          # Conditional branch to a loop or block.
          class BranchIf < LabelInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x0d
            end

            sig { override.returns(String) }
            def wat
              "br_if $#{@label}"
            end
          end

          # Represents the +call+ instruction.
          # Call a function.
          class Call < WasmInstruction
            extend T::Sig

            sig { returns(String) }
            attr_reader :func_name

            sig { params(func_name: String).void }
            def initialize(func_name)
              @func_name = func_name
            end

            sig { override.returns(Integer) }
            def opcode
              0x10
            end

            sig { override.returns(String) }
            def wat
              "call $#{@func_name}"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != Call
                return false
              end

              @func_name.eql?(other.func_name)
            end
          end

          # Represents the +end+ instruction.
          # Mark the end of a +block+, +if+, +loop+, etc.
          class End < WasmInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x0b
            end

            sig { override.returns(String) }
            def wat
              "end"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              other.class == End
            end
          end

          # Represents the +if+ instruction.
          # Execute a statement if the last item on the stack is true.
          class If < WasmInstruction
            extend T::Sig

            sig { returns(T.nilable(Else)) }
            attr_accessor :else_branch

            sig { params(else_branch: T.nilable(Else)).void }
            def initialize(else_branch: nil)
              @else_branch = else_branch
            end

            sig { override.returns(Integer) }
            def opcode
              0x04
            end

            sig { override.returns(String) }
            def wat
              "if"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              other.class == If
            end
          end

          # Represents the +else+ instruction.
          # Can be used with the +if+ instruction to execute a statement if the
          # last item on the stack is false.
          class Else < WasmInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x05
            end

            sig { override.returns(String) }
            def wat
              "else"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              other.class == Else
            end
          end

          # Represents the +loop+ instruction.
          # Create a label which can be branched to.
          class Loop < LabelInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x03
            end

            sig { override.returns(String) }
            def wat
              "loop $#{@label}"
            end
          end

          # Represents the +return+ instruction.
          # Return from a function.
          class Return < WasmInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x0f
            end

            sig { override.returns(String) }
            def wat
              "return"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              other.class == Return
            end
          end

          # Represents +0x40+, the type of an empty block.
          # https://webassembly.github.io/spec/core/binary/instructions.html#control-instructions
          class EmptyType < WasmInstruction
            extend T::Sig

            sig { override.returns(Integer) }
            def opcode
              0x40
            end

            sig { override.returns(String) }
            def wat
              "nop"
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              other.class == EmptyType
            end
          end
        end
      end
    end
  end
end
