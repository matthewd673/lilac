# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization_pass"

module Lilac
  module Optimization
    # The ConstCondJumps optimization turns conditional jumps with a constant
    # conditional value into unconditional jumps.
    class ConstCondJumps < OptimizationPass
      extend T::Sig
      extend T::Generic

      Unit = type_member { { fixed: T::Array[IL::Statement] } }

      sig { override.returns(String) }
      def self.id
        "const_cond_jumps"
      end

      sig { override.returns(String) }
      def self.description
        "Replace constant conditional jumps with unconditional jumps"
      end

      sig { override.returns(Integer) }
      def self.level
        1
      end

      sig { override.returns(UnitType) }
      def self.unit_type
        UnitType::StatementList
      end

      sig { params(stmt_list: Unit).void }
      def initialize(stmt_list)
        @stmt_list = stmt_list
      end

      sig { override.void }
      def run!
        replacement = []

        @stmt_list.each_with_index do |s, i|
          # precompute jz
          if s.is_a?(IL::JumpZero) && s.cond.is_a?(IL::Constant)
            cond = T.cast(s.cond, IL::Constant)
            if cond.value == 0
              replacement.push({ index: i, stmt: IL::Jump.new(s.target) })
            end
          # precompute jnz
          elsif s.is_a?(IL::JumpNotZero) && s.cond.is_a?(IL::Constant)
            cond = T.cast(s.cond, IL::Constant)
            if cond.value != 0
              replacement.push(index: i, stmt: IL::Jump.new(s.target))
            end
          end
        end

        replacement.each do |r|
          @stmt_list[r[:index]] = r[:stmt]
        end
      end
    end
  end
end
