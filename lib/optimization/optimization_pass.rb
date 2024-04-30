# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "optimization"
require_relative "../pass"
require_relative "../il"

module Optimization
  class OptimizationPass < Pass
  extend T::Sig
  extend T::Generic
  extend T::Helpers

  abstract!

  Unit = type_member {{ upper: Object }}

  class UnitType < T::Enum
    extend T::Sig

    enums do
      None = new
      StatementList = new
      BasicBlock = new
      InstructionList = new
    end
  end

  sig { abstract.returns(Integer) }
  def level; end

  sig { abstract.returns(UnitType) }
  def unit_type; end

  sig { params(unit: Unit).void }
  def run(unit)
    raise "run is unimplemented for #{id}"
  end

  sig { returns(String) }
  def to_s
    "#{id} (#{level}): #{description}"
  end
  end
end
