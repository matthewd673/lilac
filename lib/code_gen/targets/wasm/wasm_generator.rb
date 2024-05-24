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
            @module = root_component
            @functions = T.let([], T::Array[Components::Func])
            @func_indices = T.let({}, T::Hash[String, Integer])
            @imports = T.let([], T::Array[Components::Import])
            @start = T.let(nil, T.nilable(Components::Start))

            @writer = T.let(HexWriter.new, HexWriter)
            @sig_map = T.let({}, T::Hash[T::Array[T::Array[Type]], Integer])
            @sig_arr = T.let([], T::Array[T::Array[T::Array[Type]]])
          end

          sig { override.returns(String) }
          def generate
            # prepare to generate
            collect_components
            create_signatures_map

            # write header
            write_magic_number
            write_version

            write_type_section
            write_import_section
            write_function_section

            if @start
              write_start_section
            end

            write_code_section

            @writer.to_s
          end

          private

          sig { void }
          def collect_components
            @module.components.each do |c|
              case c
              when Components::Func
                @functions.push(c)
              when Components::Import
                @imports.push(c)
              when Components::Start
                @start = c
              end
            end
          end

          sig { void }
          def create_signatures_map
            num = 0

            @imports.each do |i|
              signature = [i.param_types, i.results]
              next if @sig_map.key?(signature)

              @sig_map[signature] = num
              @sig_arr.push(signature)
              num += 1
            end

            @functions.each do |f|
              signature = [f.params.map(&:type), f.results]
              next if @sig_map.key?(signature)

              @sig_map[signature] = num
              @sig_arr.push(signature)
              num += 1
            end
          end

          sig { params(name: String).void }
          # Give a function an index in the @func_indices table.
          # NOTE: "the [function] index space starts at zero with the function
          # imports (if any) followed by the functions defined within the
          # module."
          # https://github.com/WebAssembly/design/blob/main/Modules.md#function-index-space
          def mark_function_index(name)
            return if @func_indices[name]

            @func_indices[name] = @func_indices.keys.length
          end

          sig { void }
          def write_magic_number
            @writer.write(0x00, 0x61, 0x73, 0x6d)
          end

          sig { void }
          def write_version
            @writer.write(0x01, 0x00, 0x00, 0x00)
          end

          sig { void }
          def write_type_section
            # write section header
            # LAYOUT: id, size, num functions
            @writer.write(SECTION_TYPE)

            # Write all bytes in section to section writer.
            # Then, once we're done,kwe can write the correct section size
            # to the main @writer and then concat the section writer's bytes.
            sw = HexWriter.new
            # num functions
            sw.write_all(LEB128.encode_unsigned(@functions.length))

            # write all function signatures
            # LAYOUT: FUNC, num params, [param types], num results, [res. types]
            @sig_arr.each do |s|
              params = T.unsafe(s[0])
              results = T.unsafe(s[1])

              sw.write(FUNC)

              # param length and params
              sw.write_all(LEB128.encode_unsigned(params.length))
              params.each do |p|
                sw.write(T.unsafe(TYPE_MAP[p]))
              end

              # result length and results
              sw.write_all(LEB128.encode_unsigned(results.length))
              results.each do |r|
                sw.write(T.unsafe(TYPE_MAP[r]))
              end
            end

            # finish by writing section size and then section bytes
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { void }
          def write_import_section
            # write section header
            # LAYOUT: id, size, num imports
            @writer.write(SECTION_IMPORT)

            # create section writer
            sw = HexWriter.new
            # num imports
            sw.write_all(LEB128.encode_unsigned(@imports.length))

            # write all imports
            # LAYOUT: str len, module name, str len, field name,
            #         import kind, import func sig index
            @imports.each do |i|
              sw.write_all(LEB128.encode_unsigned(i.module_name.length))
              sw.write_utf_8(i.module_name)

              sw.write_all(LEB128.encode_unsigned(i.func_name.length))
              sw.write_utf_8(i.func_name)

              # NOTE: for now, all imports are function imports
              sw.write(KIND_FUNC)
              mark_function_index(i.func_name)

              # signature index
              ind = T.unsafe(@sig_map[[i.param_types, i.results]])
              sw.write_all(LEB128.encode_unsigned(ind))
            end

            # write section size then concat section contents
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { void }
          def write_function_section
            # write section header
            # LAYOUT: id, size, num functions
            @writer.write(SECTION_FUNCTION)

            # create section writer
            sw = HexWriter.new
            sw.write_all(LEB128.encode_unsigned(@functions.length))

            # write all function signatures
            # LAYOUT: signature index
            @functions.each do |f|
              ind = T.unsafe(@sig_map[[f.params.map(&:type), f.results]])
              sw.write_all(LEB128.encode_unsigned(ind))
              mark_function_index(f.name)
            end

            # write section size then concat section contents
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { void }
          def write_start_section
            # write section header
            # LAYOUT: id, size, start function index
            @writer.write(SECTION_START)

            # create section writer
            sw = HexWriter.new

            # get start function index
            ind = @func_indices[T.unsafe(@start&.name)]

            unless ind
              raise "No index for start function \"#{@start&.name}\:"
            end

            sw.write_all(LEB128.encode_unsigned(ind))

            # write section size and concat section contents
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { void }
          def write_code_section
            # write section header
            # LAYOUT: id, size, num functions
            @writer.write(SECTION_CODE)

            # create section writer
            sw = HexWriter.new
            sw.write_all(LEB128.encode_unsigned(@functions.length))

            # write all func bodies
            @functions.each do |f|
              bw = write_func_body(f)

              # write body size to section writer,
              # then concat body writer contents
              sw.write_all(LEB128.encode_unsigned(bw.length))

              bw.each { |b| sw.write(b) }
            end

            # write section size and concat section contents
            @writer.write_all(LEB128.encode_unsigned(sw.length))
            sw.each { |b| @writer.write(b) }
          end

          sig { params(func: Components::Func).returns(HexWriter) }
          def write_func_body(func)
            # create body writer
            bw = HexWriter.new

            # write locals
            # LAYOUT: local decl count, [local type count, local type]
            bw.write_all(LEB128.encode_unsigned(func.locals_map.length))

            # write local counts and types
            # also, build a map of local name => index to lookup from later
            total_locals = 0

            local_indices = {}
            # add func params to local_indices first
            func.params.each do |p|
              local_indices[p.name] = total_locals
              total_locals += 1
            end

            func.locals_map.each_key do |t|
              locals = T.unsafe(func.locals_map[t])
              bw.write_all(LEB128.encode_unsigned(locals.length))
              bw.write(T.unsafe(TYPE_MAP[t]))

              locals.each do |l|
                local_indices[l.name] = total_locals
                total_locals += 1
              end
            end

            # write instructions
            func.instructions.each do |i|
              bw.write(i.opcode) # always write opcode

              # need to write more for some instructions
              case i
              when Instructions::ConstInteger
                bw.write_all(LEB128.encode_signed(i.value.to_i))
              when Instructions::LocalGet
                ind = LEB128.encode_unsigned(local_indices[i.variable])
                bw.write_all(ind)
              when Instructions::LocalSet
                ind = LEB128.encode_unsigned(local_indices[i.variable])
                bw.write_all(ind)
              when Instructions::LocalTee
                ind = LEB128.encode_unsigned(local_indices[i.variable])
                bw.write_all(ind)
              when Instructions::Call
                ind = T.unsafe(@func_indices[i.func_name])
                bw.write_all(LEB128.encode_unsigned(ind))
              # TODO: fill in for globals, float consts, etc.
              end
            end

            bw
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
