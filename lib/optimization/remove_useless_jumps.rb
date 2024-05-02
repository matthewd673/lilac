# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

module Optimization
  # RemoveUselessJumps is an optimization that removes jumps that point
  # to the very next statement. For example: +jmp L1+ followed by +L1:+.
  class RemoveUselessJumps < OptimizationPass
    extend T::Sig
    extend T::Generic

    Unit = type_member { { fixed: T::Array[IL::Statement] } }

    sig { override.returns(String) }
    def id
      "remove_useless_jumps"
    end

    sig { override.returns(String) }
    def description
      "Remove jumps to the very next statement"
    end

    sig { override.returns(Integer) }
    def level
      0
    end

    sig { override.returns(UnitType) }
    def unit_type
      UnitType::StatementList
    end

    sig { params(unit: Unit).void }
    def run(unit)
      stmt_list = unit # alias

      deletion = []

      stmt_list.each do |s|
        # identify labels directly below a jump that points to them
        last = T.unsafe(stmt_list[-1]) # NOTE: workaround for sorbet 7006
        if s.is_a?(IL::Label) && last && last.is_a?(IL::Jump) &&
           last.target.eql?(s.name) && !last.class.method_defined?(:cond)
          deletion.push(last)
        end
      end

      deletion.each do |d|
        stmt_list.delete(d)
      end
    end
  end
end
