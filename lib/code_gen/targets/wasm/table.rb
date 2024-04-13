# typed: strict
require "sorbet-runtime"
require_relative "../../code_gen"
require_relative "../../table"
require_relative "type"
require_relative "instructions"

class CodeGen::Targets::Wasm::Table < CodeGen::Table
  extend T::Sig

  include CodeGen
  include CodeGen::Targets::Wasm

  sig { void }
  def initialize
    super

    # define all rules for this table
    add_rule(Pattern::StatementWildcard.new,
             0,
             Instructions::Const.new(Type::I32, 5))
  end
end
