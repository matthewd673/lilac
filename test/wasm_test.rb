# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/il"
require_relative "../lib/code_gen/targets/wasm/wasm_translator"
require_relative "../lib/code_gen/targets/wasm/wasm_generator"

class WasmTest < Minitest::Test
  extend T::Sig

  include Lilac

  sig { void }
  def test_programs_produce_valid_wasm
    # attempt to compile each "fancy" program
    Dir["test/programs/fancy/*"].each do |f|
      program = Frontend::Parser.parse_file(f)

      cfg_program = IL::CFGProgram.from_program(program)

      translator = CodeGen::Targets::Wasm::WasmTranslator.new(cfg_program)
      wasm_module = translator.translate

      wasm_generator = CodeGen::Targets::Wasm::WasmGenerator.new(wasm_module)
      wasm = wasm_generator.generate

      output = File.open("output.tmp.txt", "w")
      output.write(wasm)
      output.close

      assert system("wasm-validate output.tmp.txt")
    end

    # clean up output
    system("rm output.tmp.txt")
  end
end
