# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "../../../visitor"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"

# A WatGenerator generates valid Wat from Wasm instructions.
class CodeGen::Targets::Wasm::WatGenerator < CodeGen::Generator
  extend T::Sig

  include CodeGen::Targets::Wasm

  sig { params(root_component: Components::WasmComponent).void }
  def initialize(root_component)
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)

    super(root_component)
  end

  sig { returns(String) }
  def generate
    # NOTE: expect @components to be a single Module
    @visitor.visit(@root_component)
  end

  private

  VISIT_ARRAY = T.let(-> (v, o, c) {
    str = ""
    o.each { |element|
      str += "#{v.visit(element, ctx: c)}\n"
    }
    str.chomp!
    return str
  }, Visitor::Lambda)

  VISIT_MODULE = T.let(-> (v, o, c) {
    "(module\n#{v.visit(o.components, ctx: "  ")}\n)"
  }, Visitor::Lambda)

  VISIT_IMPORT = T.let(-> (v, o, c) {
    import_str = "(import \"#{o.module_name}\" \"#{o.func_name}\")"

    # stringify param types
    params_str = " "
    o.param_types.each { |t|
      params_str += "(param #{t})"
    }
    params_str.chomp!(" ")

    # stringify return type
    result_str = ""
    if o.result
      result_str = " (result #{o.result})"
    end

    "#{c}(func $#{o.func_name} #{import_str}#{params_str}#{result_str})"
  }, Visitor::Lambda)

  VISIT_FUNC = T.let(-> (v, o, c) {
    # stringify params
    params_str = " "
    o.params.each { |p|
      params_str += "#{v.visit(p)} "
    }
    params_str.chomp!(" ")

    # stringify return type
    result_str = ""
    if o.result
      result_str = " (result #{o.result})"
    end

    # stringify instructions
    instructions_str = v.visit(o.instructions, ctx: c + "  ")
    instructions_str.chomp!

    "#{c}(func $#{o.name}#{params_str}#{result_str}\n#{instructions_str}\n#{c})"
  }, Visitor::Lambda)

  VISIT_FUNCPARAM = T.let(-> (v, o, c) {
    "(param $#{o.name} #{o.type})"
  }, Visitor::Lambda)

  VISIT_START = T.let(-> (v, o, c) {
    "#{c}(start $#{o.name})"
  }, Visitor::Lambda)

  VISIT_INSTRUCTION = T.let(-> (v, o, c) {
    "#{c}#{o.wat}"
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    Array => VISIT_ARRAY,
    Components::Module => VISIT_MODULE,
    Components::Import => VISIT_IMPORT,
    Components::Func => VISIT_FUNC,
    Components::FuncParam => VISIT_FUNCPARAM,
    Components::Start => VISIT_START,
    Instruction => VISIT_INSTRUCTION,
  }, Visitor::LambdaHash)
end
