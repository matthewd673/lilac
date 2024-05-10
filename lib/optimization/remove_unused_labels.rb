# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization_pass"
require_relative "../il"

module Lilac
  module Optimization
    # The RemoveUnusedLabels optimization removes labels that are never targeted
    # by a jump.
    class RemoveUnusedLabels < OptimizationPass
      extend T::Sig
      extend T::Generic

      Unit = type_member { { fixed: T::Array[IL::Statement] } }

      sig { override.returns(String) }
      def self.id
        "remove_unused_labels"
      end

      sig { override.returns(String) }
      def self.description
        "Remove labels that are never targeted"
      end

      sig { override.returns(Integer) }
      def self.level
        0
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
        # find all labels that are jumped to
        jumped_labels = []
        @stmt_list.each do |s|
          unless s.is_a?(IL::Jump) then next end

          if jumped_labels.include?(s.target) then next end

          jumped_labels.push(s.target)
        end

        # delete all labels that aren't jumped to
        deletion = []
        @stmt_list.each do |s|
          # only labels are relevant
          unless s.is_a?(IL::Label)
            next
          end

          # only delete label if it is not jumped to
          unless jumped_labels.include?(s.name)
            deletion.push(s)
          end
        end

        deletion.each do |d|
          @stmt_list.delete(d)
        end
      end
    end
  end
end
