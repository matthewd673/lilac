# typed: strict
require "sorbet-runtime"
require_relative "code_gen"

class CodeGen::Generator
  extend T::Sig

  include CodeGen

  sig { params(table: Table).void }
  def initialize(table)
    @table = table
  end

  sig { params(stmt: IL::Statement).void }
  # TODO: placeholder-ish function to just generate an
  # Instruction from a single Statement. The actual
  # generate function should do a whole Program (probably
  # a CFGProgram).
  def generate(stmt)
    # TODO: a lot of temp printing here
    puts "found instructions for #{stmt.to_s}:"
    @table.find_rule_matches(stmt).each { |r|
      puts @table.get_rule_instruction(r)
    }
  end
end
