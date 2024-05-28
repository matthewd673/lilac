# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/il"
require_relative "../lib/code_gen/targets/wasm/wasm_translator"
require_relative "../lib/code_gen/targets/wasm/wasm_generator"

class ValidWasmTest < Minitest::Test
  extend T::Sig

  include Lilac

  OUTPUT_FILE_NAME = "output.tmp.wasm"

  sig { void }
  def test_produce_valid_wasm
    # attempt to compile each "fancy" program
    Dir["test/programs/fancy/*"].each do |f|
      program = Frontend::Parser.parse_file(f)

      cfg_program = IL::CFGProgram.from_program(program)

      translator = CodeGen::Targets::Wasm::WasmTranslator.new(cfg_program)
      wasm_module = translator.translate

      wasm_generator = CodeGen::Targets::Wasm::WasmGenerator.new(wasm_module)
      wasm = wasm_generator.generate

      output = File.open(OUTPUT_FILE_NAME, "w")
      output.write(wasm)
      output.close

      assert(system("wasm-validate #{OUTPUT_FILE_NAME}"),
             message { "wasm-validate failed for file #{f}" })
    end

    # clean up output
    system("rm #{OUTPUT_FILE_NAME}")
  end
end
