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

  sig { returns(T::Array[Instruction]) }
  def generate_instructions
    # TODO: a lot of temp stuff here

    instructions = []

    first_stmt = T.let(nil, T.nilable(IL::Statement))
    @program.cfg.each_node { |b|
      b.stmt_list.each { |s|
        instructions.concat(@table.transform(s))
      }
    }

    return instructions
  end
end
