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
end
