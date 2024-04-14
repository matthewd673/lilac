# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

class CodeGen::Generator
  extend T::Sig

  include CodeGen

  sig { params(table: Table, cfg_program: IL::CFGProgram).void }
  def initialize(table, cfg_program)
    @table = table
    @program = cfg_program
  end

  protected

  sig { returns(T::Array[Instruction]) }
  def generate_instructions
    instructions = []

    # TODO: add function support
    @program.cfg.each_node { |b|
      b.stmt_list.each { |s|
        instructions.concat(@table.transform(s))
      }
    }

    return instructions
  end
end
