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
        UnitType::BasicBlock
      end

      sig { params(block: Analysis::BB).void }
      def initialize(block)
        @block = block
      end

      sig { override.void }
      def run!
        # precompute jz
        if @block.exit&.is_a?(IL::JumpZero) &&
           T.cast(@block.exit, IL::JumpZero).cond.is_a?(IL::Constant)
          cond = T.cast(T.cast(@block.exit, IL::JumpZero).cond, IL::Constant)
          target = T.cast(@block.exit&.target, String)
          if cond.value == 0
            @block.exit = IL::Jump.new(target)
          end
        # precompute jnz
        elsif @block.exit&.is_a?(IL::JumpNotZero) &&
              T.cast(@block.exit, IL::JumpNotZero).cond.is_a?(IL::Constant)
          cond = T.cast(T.cast(@block.exit, IL::JumpNotZero).cond, IL::Constant)
          target = T.cast(@block.exit&.target, String)
          if cond.value != 0
            @block.exit == IL::Jump.new(target)
          end
        end
      end
    end
  end
end
