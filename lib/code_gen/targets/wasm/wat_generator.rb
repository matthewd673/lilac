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
    # generate instructions
    instructions = []

    # keep track of local variable declarations
    locals = []

    # TODO: add function support
    @program.cfg.each_node { |b|
      b.stmt_list.each { |s|
        # insert declarations for local variables when appropriate
        if s.is_a?(IL::Definition)
          # only declare once
          if locals.include?(s.id.name)
            next
          end

          # TODO: proper type for decl
          decl = Instructions::Local.new(Type::I32, s.id.name)
          instructions.push(decl)
          locals.push(s.id.name)
        end
      }

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
