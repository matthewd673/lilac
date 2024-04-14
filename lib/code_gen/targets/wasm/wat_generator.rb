# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "../../../il"
require_relative "../../../visitor"
require_relative "table"

class CodeGen::Targets::Wasm::WatGenerator < CodeGen::Generator
  extend T::Sig

  include CodeGen::Targets::Wasm::Instructions

  sig { params(cfg_program: IL::CFGProgram).void }
  def initialize(cfg_program)
    super(CodeGen::Targets::Wasm::Table.new, cfg_program)
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
  end

  sig { returns(String) }
  def generate
    instructions = generate_instructions
    @visitor.visit(instructions)
  end

  private

  VISIT_ARRAY = T.let(-> (v, o, c) {
    str = ""
    o.each { |instruction|
      str += v.visit(instruction) + "\n"
    }
    str.chomp!
    return str
  }, Visitor::Lambda)

  VISIT_INSTRUCTION = T.let(-> (v, o, c) {
    o.wat
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    Array => VISIT_ARRAY,
    CodeGen::Targets::Wasm::Instruction => VISIT_INSTRUCTION,
  }, Visitor::LambdaHash)
end
