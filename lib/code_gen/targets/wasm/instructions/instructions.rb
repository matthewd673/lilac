# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../../instruction"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # The Wasm::Instructions module contains definitions for classes of
        # instructions in Wasm as well as the actual instructions defined in the
        # Wasm spec.
        module Instructions
          extend T::Sig

          include CodeGen
          include CodeGen::Targets::Wasm

          # HELPER FUNCTIONS

          sig { params(il_type: IL::Types::Type).returns(Type) }
          # Convert an IL::Type into a Wasm type. Not all IL types are supported
          # by Wasm.
          #
          # @param [IL::Type::Type] il_type The IL type to convert.
          # @return [Type] The corresponding Wasm type.
          def self.to_wasm_type(il_type)
            case il_type
            when IL::Types::I32 then Type::I32
            when IL::Types::I64 then Type::I64
            when IL::Types::F32 then Type::F32
            when IL::Types::F64 then Type::F64
            else
              raise "IL type #{il_type} is not supported by Wasm"
            end
          end

          sig { params(il_type: IL::Types::Type).returns(IntegerType) }
          # Convert an IL::Type into a Wasm integer type (I32 or I64). If the
          # provided IL type cannot be converted to an integer type this will
          # raise an exception.
          #
          # @param [IL::Type] il_type The IL type to convert.
          # @return [Type] An integer Wasm type (either I32 or I64).
          def self.to_integer_type(il_type)
            case il_type
            when IL::Types::I32 then Type::I32
            when IL::Types::I64 then Type::I64
            else
              raise "IL type #{il_type} is not an integer type or "\
                    "not supported by Wasm"
            end
          end

          sig { params(il_type: IL::Types::Type).returns(FloatType) }
          # Convert an IL::Type into a Wasm floating point type (F32 or F64).
          # If the provided IL type cannot be converted to a floating point type
          # this will raise an exception.
          #
          # @param [IL::Type] il_type The IL type to convert.
          # @return [Type] An integer Wasm type (either F32 or F64).
          def self.to_float_type(il_type)
            case il_type
            when IL::Types::F32 then Type::F32
            when IL::Types::F64 then Type::F64
            else
              raise "IL type #{il_type} is not an integer type or "\
                    "not supported by Wasm"
            end
          end

          # INSTRUCTION CLASSES

          # A generic Wasm instruction.
          class WasmInstruction < CodeGen::Instruction
            extend T::Sig
            extend T::Helpers

            abstract!

            sig { abstract.returns(Integer) }
            def opcode; end

            sig { abstract.returns(String) }
            def wat; end
          end

          # A Wasm instruction with a type (e.g.: +add+).
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

            sig { override.returns(Integer) }
            def hash
              [self.class, @type].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @type.eql?(other.type)
            end
          end

          # A Wasm instruction that requires an integer type argument
          # (e.g.: +div_s+).
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

            sig { override.returns(Integer) }
            def hash
              [self.class, @type].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @type.eql?(other.type)
            end
          end

          # A Wasm instruction that requires a floating point type argument
          # (e.g.: +div+).
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

            sig { override.returns(Integer) }
            def hash
              [self.class, @type].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @type.eql?(other.type)
            end
          end

          # A Wasm instruction that requires a variable name argument
          # (e.g.: +local.get+).
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

            sig { override.returns(Integer) }
            def hash
              [self.class, @variable].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @variable.eql?(other.variable)
            end
          end

          # A Wasm instruction that requires a label name (e.g.: +loop+).
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

            sig { override.returns(Integer) }
            def hash
              [self.class, @label].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @label.eql?(other.label)
            end
          end

          # A Wasm instruction that requires a memory name. A +nil+ memory
          # name indicates default memory.
          class MemoryInstruction < WasmInstruction
            extend T::Sig
            extend T::Helpers

            abstract!

            sig { returns(T.nilable(String)) }
            attr_reader :memory

            sig { params(memory: T.nilable(String)).void }
            def initialize(memory)
              @memory = memory
            end

            sig { override.returns(Integer) }
            def hash
              [self.class, @memory].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @memory.eql?(other.memory)
            end
          end

          # A Wasm instruction that requires a type and a memory name.
          # A +nil+ memory name indicates default memory.
          class TypedMemoryInstruction < WasmInstruction
            extend T::Sig
            extend T::Helpers

            abstract!

            sig { returns(Type) }
            attr_reader :type

            sig { returns(T.nilable(String)) }
            attr_reader :memory

            sig { params(type: Type, memory: T.nilable(String)).void }
            def initialize(type, memory)
              @type = type
              @memory = memory
            end

            sig { override.returns(Integer) }
            def hash
              [self.class, @type, @memory].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @memory.eql?(other.memory)
            end
          end

          # A Wasm instruction that requires an integer type and a memory name.
          # A +nil+ memory name indicates default memory.
          class IntegerMemoryInstruction < WasmInstruction
            extend T::Sig
            extend T::Helpers

            abstract!

            sig { returns(T.any(Type::I32, Type::I64)) }
            attr_reader :type

            sig { returns(T.nilable(String)) }
            attr_reader :memory

            sig do
              params(type: T.any(Type::I32, Type::I64),
                     memory: T.nilable(String))
                .void
            end
            def initialize(type, memory)
              @type = type
              @memory = memory
            end

            sig { override.returns(Integer) }
            def hash
              [self.class, @type, @memory].hash
            end

            sig { override.params(other: T.untyped).returns(T::Boolean) }
            def eql?(other)
              if other.class != self.class
                return false
              end

              @memory.eql?(other.memory)
            end
          end
        end
      end
    end
  end
end
