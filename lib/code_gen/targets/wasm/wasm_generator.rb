# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "../../../visitor"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"
require_relative "hex_writer"
require_relative "leb128"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # A WasmGenerator generates a valid Wasm binary from Wasm instructions.
        class WasmGenerator < CodeGen::Generator
          extend T::Sig

          include CodeGen::Targets::Wasm

          sig { params(root_component: Components::Module).void }
          def initialize(root_component)
            @writer = T.let(HexWriter.new, HexWriter)
            @module = root_component
          end

          sig { override.returns(String) }
          def generate
            # write header
            write_magic_number
            write_version

            # collect components from the module
            functions = []
            @module.components.each do |c|
              next unless c.is_a?(Components::Func)

              functions.push(c)
            end

            imports = []
            @module.components.each do |c|
              next unless c.is_a?(Components::Import)

              imports.push(c)
            end

            write_type_section(functions, imports)

            @writer.to_s
          end

          private

          sig { void }
          def write_magic_number
            @writer.write(0x00, 0x61, 0x73, 0x6d)
          end

          sig { void }
          def write_version
            @writer.write(0x01, 0x00, 0x00, 0x00)
          end

          sig do
            params(functions: T::Array[Components::Func],
                   imports: T::Array[Components::Import])
              .void
          end
          def write_type_section(functions, imports)
            # write section header
            # LAYOUT: id, size, num functions
            @writer.write(SECTION_TYPE)

            # Write all bytes in section to section writer.
            # Then, once we're done, we can write the correct section size
            # to the main @writer and then concat the section writer's bytes.
            sw = HexWriter.new
            sw.write_all(LEB128.encode_unsigned(functions.length))

            # write all function signatures
            # LAYOUT: FUNC, num params, [param types], num results, [res. types]
            functions.each do |f|
              sw.write(FUNC)
              sw.write_all(LEB128.encode_unsigned(f.params.length))

              f.params.each do |p|
                sw.write(T.unsafe(TYPE_MAP[p.type]))
              end

              # NOTE: Lilac is only capable of generating functions with
              # 0 or 1 results.
              if f.result
                sw.write_all(LEB128.encode_unsigned(1))
                sw.write(T.unsafe(TYPE_MAP[T.unsafe(f.result)]))
              else
                sw.write_all(LEB128.encode_unsigned(0))
              end
            end

            # TODO: write imports as functions

            # finish by writing section size and then section bytes
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          FUNC = T.let(0x60, Integer)

          private_constant :FUNC

          TYPE_MAP = T.let({
            Type::I32 => 0x7f,
            Type::I64 => 0x7e,
            Type::F32 => 0x7d,
            Type::F64 => 0x7c,
          }.freeze, T::Hash[Type, Integer])

          private_constant :TYPE_MAP

          SECTION_TYPE = T.let(1, Integer)
          SECTION_IMPORT = T.let(2, Integer)
          SECTION_FUNCTION = T.let(3, Integer)
          SECTION_TABLE = T.let(4, Integer)
          SECTION_MEMORY = T.let(5, Integer)
          SECTION_GLOBAL = T.let(6, Integer)
          SECTION_EXPORT = T.let(7, Integer)
          SECTION_START = T.let(8, Integer)
          SECTION_ELEMENT = T.let(9, Integer)
          SECTION_CODE = T.let(10, Integer)
          SECTION_DATA = T.let(11, Integer)
          SECTION_DATACOUNT = T.let(12, Integer)

          private_constant :SECTION_TYPE
          private_constant :SECTION_IMPORT
          private_constant :SECTION_FUNCTION
          private_constant :SECTION_TABLE
          private_constant :SECTION_MEMORY
          private_constant :SECTION_GLOBAL
          private_constant :SECTION_EXPORT
          private_constant :SECTION_START
          private_constant :SECTION_ELEMENT
          private_constant :SECTION_CODE
          private_constant :SECTION_DATA
          private_constant :SECTION_DATACOUNT
        end
      end
    end
  end
end
