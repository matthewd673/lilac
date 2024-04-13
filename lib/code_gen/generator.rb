# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "../il"

class CodeGen::Generator
  extend T::Sig

  include CodeGen

  sig { params(table: Table, program: IL::CFGProgram).void }
  def initialize(table, program)
    @table = table
    @program = program
  end

  sig { returns(T.nilable(Instruction)) }
  # TODO: placeholder-ish function to just generate an
  # Instruction from a single Statement. The actual
  # generate function should do a whole Program (probably
  # a CFGProgram).
  def generate_instructions
    # TODO: a lot of temp stuff here
    # TESTING: get first statement in cfg and try to match it
    first_stmt = T.let(nil, T.nilable(IL::Statement))
    @program.cfg.each_node { |b|
      if b == @program.cfg.entry then next end
      first_stmt = b.stmt_list[0]
      break
    }

    if not first_stmt
      raise("No statement in program")
    else
      puts "first stmt: #{first_stmt}"
    end

    @table.find_rule_matches(first_stmt).each { |r|
      rule_ins = @table.get_rule_instruction(r)
      puts rule_ins
      return rule_ins
    }

    return nil
  end
end
