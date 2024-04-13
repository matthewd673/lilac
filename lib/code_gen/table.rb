# typed: strict
require "sorbet-runtime"
require_relative "code_gen"
require_relative "instruction"

class CodeGen::Table
  extend T::Sig

  Rule = T.type_alias { T.any(IL::Statement, IL::Expression, IL::Value) }

  class RuleValue # TODO: there has to be a better name for this
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :cost
    sig { returns(CodeGen::Instruction) }
    attr_reader :instruction

    sig { params(cost: Integer, instruction: CodeGen::Instruction).void }
    def initialize(cost, instruction)
      @cost = cost
      @instruction = instruction
    end
  end

  sig { void }
  def initialize
    @rules = T.let(Hash.new, T::Hash[Rule, RuleValue])
  end

  sig { params(block: T.proc.params(arg0: Rule).void).void }
  def each_rule(&block)
    @rules.keys.each(&block)
  end

  sig { params(rule: Rule).returns(T.nilable(CodeGen::Instruction)) }
  def get_rule_instruction(rule)
    value = @rules[rule]
    if not value
      nil
    else
      value.instruction
    end
  end

  protected

  sig { params(rule: Rule, cost: Integer, instruction: CodeGen::Instruction).void }
  def add_rule(rule, cost, instruction)
    @rules[rule] = RuleValue.new(cost, instruction)
  end
end
