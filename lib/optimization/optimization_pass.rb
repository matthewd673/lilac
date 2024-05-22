# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../pass"
require_relative "../il"

module Lilac
  module Optimization
    # An OptimizationPass is a Pass that runs an optimization.
    class OptimizationPass < Pass
      extend T::Sig
      extend T::Helpers

      abstract!

      # A UnitType describes the type of object that an Optimization works on.
      # For example, if an Optimization runs on an object of type
      # +T::Array[IL::Statement]+, its UnitType would be
      # +UnitType::StatementList+.
      class UnitType < T::Enum
        extend T::Sig

        enums do
          # Should never be used.
          None = new
          # A basic block.
          BasicBlock = new
          # A CFG.
          CFG = new
          # An array of machine-dependent instructions. Only to be used for
          #   machine-dependent optimizations.
          InstructionList = new
        end
      end

      sig { abstract.returns(Integer) }
      def self.level; end

      sig { abstract.returns(UnitType) }
      def self.unit_type; end

      sig { returns(Integer) }
      def level
        self.class.level
      end

      sig { returns(UnitType) }
      def unit_type
        self.class.unit_type
      end

      sig { returns(String) }
      def to_s
        "#{self.class.id} (#{self.class.level}): #{self.class.description}"
      end
    end
  end
end
