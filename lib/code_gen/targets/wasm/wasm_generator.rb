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

            write_type_section(functions)
            write_import_section(imports)

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

          sig { params(functions: T::Array[Components::Func]).void }
          def write_type_section(functions)
            # write section header
            # LAYOUT: id, size, num functions
            @writer.write(SECTION_TYPE)

            # Write all bytes in section to section writer.
            # Then, once we're done, we can write the correct section size
            # to the main @writer and then concat the section writer's bytes.
            sw = HexWriter.new
            # num functions
            sw.write_all(LEB128.encode_unsigned(functions.length))

            # write all function signatures
            # LAYOUT: FUNC, num params, [param types], num results, [res. types]
            functions.each do |f|
              sw.write(FUNC)

              # param length and params
              sw.write_all(LEB128.encode_unsigned(f.params.length))
              f.params.each do |p|
                sw.write(T.unsafe(TYPE_MAP[p.type]))
              end

              # result length and results
              sw.write_all(LEB128.encode_unsigned(f.results.length))
              f.results.each do |r|
                sw.write(T.unsafe(TYPE_MAP[r]))
              end
            end

            # finish by writing section size and then section bytes
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { params(imports: T::Array[Components::Import]).void }
          def write_import_section(imports)
            # write section header
            # LAYOUT: id, size, num imports
            @writer.write(SECTION_IMPORT)

            # create section writer
            sw = HexWriter.new
            # num imports
            sw.write_all(LEB128.encode_unsigned(imports.length))

            # write all imports
            # LAYOUT: str len, module name, str len, field name,
            #         import kind, import func sig index
            imports.each_with_index do |i, ind|
              sw.write_all(LEB128.encode_unsigned(i.module_name.length))
              sw.write_utf_8(i.module_name)

              sw.write_all(LEB128.encode_unsigned(i.func_name.length))
              sw.write_utf_8(i.func_name)

              # NOTE: for now, all imports are function imports
              sw.write(KIND_FUNC)

              # signature index
              # NOTE: the generate always defines imported functions first in
              # the types section, so the index of the signature is the same as
              # the index in the imports array.
              sw.write_all(LEB128.encode_unsigned(ind))
            end

            # write section size then append section writer contents
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          # CONSTANTS

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

          KIND_FUNC = T.let(0x00, Integer)
          KIND_TABLE = T.let(0x01, Integer)
          KIND_MEM = T.let(0x02, Integer)
          KIND_GLOBAL = T.let(0x03, Integer)

          private_constant :KIND_FUNC
          private_constant :KIND_TABLE
          private_constant :KIND_MEM
          private_constant :KIND_GLOBAL
        end
      end
    end
  end
end
