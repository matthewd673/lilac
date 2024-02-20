# typed: strict
require "sorbet-runtime"
require_relative "analysis"

class LVN < Analysis
  sig { void }
  def initialize
    @id = T.let("lvn", String)
    @full_name = T.let("local value numbering", String)
    @level = T.let(1, Integer)
  end
end
