# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"
require_relative "hex_writer"

module Lilac
  module CodeGen
    module Targets
      module Wasm
        # A WasmGenerator generates a valid Wasm binary from Wasm instructions.
        class WasmGenerator < CodeGen::Generator
          extend T::Sig

          include CodeGen::Targets::Wasm

          sig { params(root_component: Components::WasmComponent).void }
          def initialize(root_component)
            @writer = T.let(HexWriter.new, HexWriter)

            super(root_component)
          end

          sig { override.returns(String) }
          def generate
            # write header
            write_magic_number
            write_version

            raise "TODO"
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

          SECTION_TYPE = T.let([0x01].freeze, T::Array[Integer])
          SECTION_FUNC = T.let([0x03].freeze, T::Array[Integer])
          SECTION_CODE = T.let([0x0a].freeze, T::Array[Integer])

          private_constant :SECTION_TYPE
          private_constant :SECTION_FUNC
          private_constant :SECTION_CODE
        end
      end
    end
  end
end
