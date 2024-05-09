# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization"
require_relative "optimization_pass"

module Lilac
  module Optimization
    # The CondenseLabels optimization finds consecutive labels and combines
    # them into a single label.
    class CondenseLabels < OptimizationPass
      extend T::Sig
      extend T::Generic

      Unit = type_member { { fixed: T::Array[IL::Statement] } }

      sig { override.returns(String) }
      def self.id
        "condense_labels"
      end

      sig { override.returns(String) }
      def self.description
        "Condense adjacent labels"
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
        jump_map = {} # target name -> IL::Goto
        label_adj_map = {} # IL::Label -> the IL::Label immediately above it

        deletion = []

        @stmt_list.each_with_index do |s, i|
          # identify adjacent labels
          last = T.unsafe(@stmt_list[i - 1]) # NOTE: workaround for sorbet 7006
          if s.is_a?(IL::Label) && last && last.is_a?(IL::Label)
            label_adj_map[s] = last
            deletion.push(s) # remove adjacent labels
          end

          # mark jumps
          if s.is_a?(IL::Jump)
            if jump_map.include?(s.target)
              jump_map[s.target].push(s)
            else
              jump_map[s.target] = [s]
            end
          end
        end

        label_adj_map.keys.reverse_each do |c|
          # redirect all jumps pointing at the adj label to its predecessor
          jump_map[c.name].each do |j|
            j.target = label_adj_map[c].name

            # copy jumps in map to reflect their new target
            # we don't have to remove them from their old location since that
            # label will never be read again (and we're iterating through that
            # collection right now so removing it would be awkward)
            if jump_map.include?(j.target)
              jump_map[j.target].push(j)
            else
              jump_map[j.target] = [j]
            end
          end
        end

        # delete all marked stmts
        deletion.each do |s|
          @stmt_list.delete(s)
        end
      end
    end
  end
end
