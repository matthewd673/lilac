# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

include Optimization

module Optimization
  class ConstCondJumps < OptimizationPass
    extend T::Sig
    extend T::Generic

    Unit = type_member { { fixed: T::Array[IL::Statement] } }

    sig { override.returns(String) }
    def id
      "const_cond_jumps"
    end

    sig { override.returns(String) }
    def description
      "Replace constant conditional jumps with unconditional jumps"
    end

    sig { override.returns(Integer) }
    def level
      1
    end

    sig { override.returns(UnitType) }
    def unit_type
      UnitType::StatementList
    end

    sig { params(unit: Unit).void }
    def run(unit)
      stmt_list = unit # alias

      replacement = []

      stmt_list.each_with_index do |s, i|
        # precompute jz
        if s.is_a?(IL::JumpZero) and s.cond.is_a?(IL::Constant)
          cond = T.cast(s.cond, IL::Constant)
          if cond.value == 0
            replacement.push({ index: i, stmt: IL::Jump.new(s.target) })
          end
        # precompute jnz
        elsif s.is_a?(IL::JumpNotZero) and s.cond.is_a?(IL::Constant)
          cond = T.cast(s.cond, IL::Constant)
          if cond.value != 0
            replacement.push(index: i, stmt: IL::Jump.new(s.target))
          end
        end
      end

      replacement.each do |r|
        stmt_list[r[:index]] = r[:stmt]
      end
    end
  end
end
