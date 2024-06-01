# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/il"
require_relative "../lib/code_gen/targets/wasm/wasm_translator"
require_relative "../lib/code_gen/targets/wasm/wat_generator"

class ValidWatTest < Minitest::Test
  extend T::Sig

  include Lilac

  OUTPUT_FILE_NAME = "output.tmp.wat"
  GENERATED_FILE_NAME = "output.tmp.wasm"

  sig { void }
  def test_produce_valid_wasm
    # attempt to compile each "fancy" program
    Dir["test/programs/fancy/*"].each do |f|
      program = Frontend::Parser.parse_file(f)

      cfg_program = IL::CFGProgram.from_program(program)

      translator = CodeGen::Targets::Wasm::WasmTranslator.new(cfg_program)
      wasm_module = translator.translate

      wat_generator = CodeGen::Targets::Wasm::WatGenerator.new(wasm_module)
      wat = wat_generator.generate

      output = File.open(OUTPUT_FILE_NAME, "w")
      output.write(wat)
      output.close

      assert(system("wat2wasm #{OUTPUT_FILE_NAME}"),
             message do
               "wat2wasm failed for file #{f}. The following Wat "\
               "is invalid:\n #{wat}"
             end)
    end

    # clean up output
    system("rm #{OUTPUT_FILE_NAME}")
    system("rm #{GENERATED_FILE_NAME}")
  end
end
