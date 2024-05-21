# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimizations"
require_relative "optimization_pass"
require_relative "../runner"

module Lilac
  module Optimization
    # An OptimizationRunner is a Runner for Optimization passes.
    class OptimizationRunner < Runner
      extend T::Sig
      extend T::Generic

      include Optimization

      P = type_member { { fixed: OptimizationPass[T.untyped] } }

      sig { params(pass: P).void }
      # Run an OptimizationPass on every statement list in the Program.
      # @param [Pass] pass The Pass to run.
      def run_pass(pass)
        # UnitType::None is a placeholder used by the parent class
        if pass.unit_type == OptimizationPass::UnitType::None
          raise "No unit type for optimization pass #{pass.id}"
        end

        # run on main program statements
        case pass.unit_type
        when OptimizationPass::UnitType::StatementList
          instance = T.unsafe(pass).new(@program.stmt_list)
          instance.run!
        when OptimizationPass::UnitType::BasicBlock
          bb_list = Analysis::BB.from_stmt_list(@program.stmt_list)

          instance = T.let(nil, T.nilable(OptimizationPass[T.untyped]))
          bb_list.each do |b|
            instance = T.unsafe(pass).new(b)
            instance.run!
          end

          stmt_list = Analysis::BB.to_stmt_list(bb_list)
          @program.stmt_list.clear
          @program.stmt_list.concat(stmt_list)
        else
          raise "Unsupported unit type for #{pass.id}"
        end
        @program.each_func do |f|
          # run on function body
          case pass.unit_type
          when OptimizationPass::UnitType::StatementList
            instance = T.unsafe(pass).new(f.stmt_list)
            instance.run!
          when OptimizationPass::UnitType::BasicBlock
            bb_list = Analysis::BB.from_stmt_list(f.stmt_list)

            instance = T.let(nil, T.nilable(OptimizationPass[T.untyped]))
            bb_list.each do |b|
              instance = T.unsafe(pass).new(b)
              instance.run!
            end

            stmt_list = Analysis::BB.to_stmt_list(bb_list)
            f.stmt_list.clear
            f.stmt_list.concat(stmt_list)
          else
            raise "Unsupported unit type for #{pass.id}"
          end
        end
      end

      sig do
        params(level: Integer)
          .returns(T::Array[T.class_of(OptimizationPass)])
      end
      # Get all of the Optimizations at a given optimization level.
      # @param [Integer] level The level to select at.
      # @return [T::Array[OptimizationPass]] A list of Optimizations.
      def level_passes(level)
        OPTIMIZATIONS.select { |o| o.level == level }
      end
    end
  end
end
