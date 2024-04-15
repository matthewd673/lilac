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

  include CodeGen::Targets::Wasm

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

  protected

  sig { returns(T::Array[Instruction]) }
  # NOTE: adapted from CodeGen::Generator.generate_instructions
  def generate_instructions
    # scan forwards to build a symbol table of all locals and their types.
    symbols = SymbolTable.new
    symbols.push_scope

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
        symbols.insert(id_symbol)
      }
    }

    # generate instructions
    instructions = []

    # insert local declarations at the top
    local_scope = symbols.top_scope
    if not local_scope # this should never happen
      raise "No scope in symbol table"
    end
    local_scope.each_symbol { |sym|
      type = Instructions::il_type_to_wasm_type(sym.type)
      decl = Instructions::Local.new(type, sym.id.name)
      instructions.push(decl)
    }

    # TODO: add function support
    @program.cfg.each_node { |b|
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
