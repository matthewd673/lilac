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
require_relative "constructs"

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
    instructions = generate_instructions
    @visitor.visit(instructions)
  end

  protected

  sig { returns(Constructs::Module) }
  # NOTE: adapted from CodeGen::Generator.generate_instructions
  def generate_instructions
    # scan forwards to build a symbol table of all locals and their types.
    @symbols.push_scope

    @program.cfg.each_node { |b|
      # scan each block for definitions and log them
      # a previous validation should have already ensured that there are no
      # inconsistent types, so we don't need any checks here.
      b.stmt_list.each { |s|
        if not s.is_a?(IL::Definition)
          next
        end

        # NOTE: if not in SSA (which it will never be by this point) this will
        # lead to duplicate inserts but the types should never change so thats
        # fine.
        id_symbol = ILSymbol.new(s.id, s.type)
        @symbols.insert(id_symbol)
      }
    }

    # generate instructions
    instructions = []

    # insert local declarations at the top
    local_scope = @symbols.top_scope
    if not local_scope # this should never happen
      raise "No scope in symbol table"
    end
    local_scope.each_symbol { |sym|
      type = Instructions::to_wasm_type(sym.type)
      decl = Instructions::Local.new(type, sym.id.name)
      instructions.push(decl)
    }

    # generate the rest of the instructions
    # TODO: add function support
    @program.cfg.each_node { |b|
      b.stmt_list.each { |s|
        # transform instruction like normal
        instructions.concat(@table.transform(s))
      }
    }

    constructs = []

    constructs.push(Constructs::Func.new("__lilac_main", instructions))
    constructs.push(Constructs::Start.new("__lilac_main"))

    wasm_module = Constructs::Module.new(constructs)

    return wasm_module
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
    "(module\n#{v.visit(o.constructs, ctx: "  ")}\n)"
  }, Visitor::Lambda)

  VISIT_FUNC = T.let(-> (v, o, c) {
    "#{c}(func $#{o.name}\n#{v.visit(o.instructions, ctx: c + "  ")}\n#{c})"
  }, Visitor::Lambda)

  VISIT_START = T.let(-> (v, o, c) {
    "#{c}(start $#{o.name})"
  }, Visitor::Lambda)

  VISIT_INSTRUCTION = T.let(-> (v, o, c) {
    "#{c}#{o.wat}"
  }, Visitor::Lambda)

  VISIT_LAMBDAS = T.let({
    Array => VISIT_ARRAY,
    Constructs::Module => VISIT_MODULE,
    Constructs::Func => VISIT_FUNC,
    Constructs::Start => VISIT_START,
    Instruction => VISIT_INSTRUCTION,
  }, Visitor::LambdaHash)
end
