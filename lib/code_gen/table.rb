# typed: strict
require "sorbet-runtime"
require_relative "code_gen"

class CodeGen::Table
  extend T::Sig

  Rule = T.type_alias { T.any(IL::Statement, IL::Expression, IL::Value) }

  class RuleValue # TODO: there has to be a better name for this
    extend T::Sig

    sig { params(cost: Integer, instruction: String).void }
    def initialize(cost, instruction)
      @cost = cost
      @instruction = instruction
    end
  end

  sig { void }
  def initialize
    @rules = T.let(Hash.new, T::Hash[Rule, RuleValue])
  end

  sig { params(rule: Rule, cost: Integer, instruction: String).void }
  def add_rule(rule, cost, instruction)
    @rules[rule] = RuleValue.new(cost, instruction)
  end
end
