# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "../pass"
require_relative "../il"

module Optimization
  # An OptimizationPass is a Pass that runs an optimization.
  class OptimizationPass < Pass
    extend T::Sig
    extend T::Generic
    extend T::Helpers

    abstract!

    Unit = type_member { { upper: Object } }

    # A UnitType describes the type of object that an Optimization is
    # working on. For example, if an Optimization runs on an object of type
    # +T::Array[IL::Statement]+, its UnitType would be
    # +UnitType::StatementList+.
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
    def self.level; end

    sig { abstract.returns(UnitType) }
    def self.unit_type; end

    sig { returns(String) }
    def to_s
      "#{self.class.id} (#{self.class.level}): #{self.class.description}"
    end
  end
end
