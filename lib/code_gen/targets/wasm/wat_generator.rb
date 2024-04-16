# typed: strict
require "sorbet-runtime"
require_relative "wasm"
require_relative "../../generator"
require_relative "../../instruction"
require_relative "../../../il"
require_relative "../../../visitor"
require_relative "../../../symbol_table"
require_relative "table"
require_relative "instructions/instructions"
require_relative "instructions/instruction_set"
require_relative "components"

class CodeGen::Targets::Wasm::WatGenerator < CodeGen::Generator
  extend T::Sig

  include CodeGen::Targets::Wasm

  sig { params(cfg_program: IL::CFGProgram).void }
  def initialize(cfg_program)
    @symbols = T.let(SymbolTable.new, SymbolTable)
    wasm_table = CodeGen::Targets::Wasm::Table.new(@symbols)
    @visitor = T.let(Visitor.new(VISIT_LAMBDAS), Visitor)

    super(wasm_table, cfg_program)
  end

  sig { returns(String) }
  def generate
    wasm_module = generate_module
    @visitor.visit(wasm_module)
  end

  protected

  sig { returns(Components::Module) }
  def generate_module
    components = []
    @symbols.push_scope # always have scope for globals and top-level

    # generate all functions
    @program.each_func { |f|
      components.push(generate_func(f))
    }

    # generate instructions for main stmt_list
    main_instructions = generate_instructions(@program.cfg)
    components.push(Components::Func.new("__lilac_main",
                                         [], # no params
                                         nil, # no return type
                                         main_instructions))
    components.push(Components::Start.new("__lilac_main"))

    wasm_module = Components::Module.new(components)

    return wasm_module
  end

  sig { params(cfg_funcdef: IL::CFGFuncDef).returns(Components::Func) }
  def generate_func(cfg_funcdef)
    params = [] # list of params for function signature

    # create a new scope with func params
    @symbols.push_scope
    cfg_funcdef.params.each { |p|
      @symbols.insert(ILSymbol.new(p.id, p.type))

      # also mark this down for the function signature
      param_type = Instructions::to_wasm_type(p.type)
      param_name = p.id.name
      params.push(Components::FuncParam.new(param_type, param_name))
    }

    # generate instructions and pop the scope we used
    instructions = generate_instructions(cfg_funcdef.cfg)
    @symbols.pop_scope

    # construct func with appropriate params and return type
    ret_type = Instructions::to_wasm_type(cfg_funcdef.ret_type)
    func = Components::Func.new(cfg_funcdef.name,
                                params,
                                ret_type,
                                instructions)
    return func
  end

  sig { params(cfg: Analysis::CFG)
          .returns(T::Array[Instructions::WasmInstruction]) }
  def generate_instructions(cfg)
    instructions = []

    # scan forwards to build a symbol table of all locals and their types.
    # NOTE: assume that our caller has kindly pushed a new scope
    cfg.each_node { |b|
      # scan each block for definitions and log them
      # a previous validation should have already ensured that there are no
      # inconsistent types, so we don't need any checks here.
      b.stmt_list.each { |s|
        if not s.is_a?(IL::Definition)
          next
        end

        # avoid redefining params
        if @symbols.lookup(s.id.key)
          next
        end

        # log in symbol table
        id_symbol = ILSymbol.new(s.id, s.type)
        @symbols.insert(id_symbol)

        # push declaration
        type = Instructions::to_wasm_type(s.type)
        decl = Instructions::Local.new(type, s.id.name)
        instructions.push(decl)
      }
    }

    # generate the rest of the instructions
    cfg.each_node { |b|
      b.stmt_list.each { |s|
        # transform instruction like normal
        instructions.concat(@table.transform(s))
      }
    }

    return instructions
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
    Components::Func => VISIT_FUNC,
    Components::FuncParam => VISIT_FUNCPARAM,
    Components::Start => VISIT_START,
    Instruction => VISIT_INSTRUCTION,
  }, Visitor::LambdaHash)
end
