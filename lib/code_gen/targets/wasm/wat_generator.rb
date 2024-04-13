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

  sig { params(program: IL::CFGProgram).void }
  def initialize(program)
    super(CodeGen::Targets::Wasm::Table.new, program)
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)
  end

  sig { void }
  def generate
    # TODO: return a nice string eventually
    instruction = generate_instructions
    puts @visitor.visit(instruction)
  end

  private

  VISIT_TYPE = T.let(-> (v, o, c) {
    o.to_s
  }, Visitor::Lambda)

  VISIT_CONST = T.let(-> (v, o, c) {
    type = o.type
    value = o.value

    "#{v.visit(type)}.const #{value}"
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    CodeGen::Targets::Wasm::Type => VISIT_TYPE,
    Const => VISIT_CONST,
  }, Visitor::LambdaHash)
end
