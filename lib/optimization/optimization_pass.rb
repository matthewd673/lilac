# typed: strict
require "sorbet-runtime"
require_relative "optimization"
require_relative "../pass"
require_relative "../il"

class Optimization::OptimizationPass < Pass
  extend T::Sig
  extend T::Generic

  Unit = type_member

  class UnitType < T::Enum
    extend T::Sig

    enums do
      None = new
      StatementList = new
      BasicBlock = new
    end
  end

  sig { returns(Integer) }
  attr_reader :level

  sig { returns(UnitType) }
  attr_reader :unit_type

  sig { void }
  def initialize
    # NOTE: these should be overwritten by subclasses
    @id = T.let("optimization", String)
    @description = T.let("Generic optimization pass", String)
    @level = T.let(-1, Integer)
    @unit_type = T.let(UnitType::None, UnitType)
  end

  sig { params(unit: Unit).void }
  def run(unit)
    raise("run is unimplemented for #{@id}")
  end

  sig { returns(String) }
  def to_s
    "#{@id} (#{@level}): #{@description}"
  end
end
