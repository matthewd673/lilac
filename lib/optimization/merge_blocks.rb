# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "optimization_pass"
require_relative "../analysis/cfg"
require_relative "../graph"

module Lilac
  module Optimization
    class MergeBlocks < OptimizationPass
      extend T::Sig

      sig { override.returns(String) }
      def self.id
        "merge_blocks"
      end

      sig { override.returns(String) }
      def self.description
        "Merge blocks in a CFG"
      end

      sig { override.returns(Integer) }
      def self.level
        0
      end

      sig { override.returns(UnitType) }
      def self.unit_type
        UnitType::CFG
      end

      sig { override.params(cfg: Analysis::CFG).void }
      def initialize(cfg)
        @cfg = cfg
      end

      sig { override.void }
      def run!
        # find all nodes with exactly one predecessor where that predecessor
        # has exactly one successor (exempt the ENTRY and EXIT nodes)
        @cfg.each_node do |b|
          next if b == @cfg.exit || @cfg.predecessors_length(b) != 1

          puts "ALMOST: #{@cfg.first_predecessor(b)}"

          p = @cfg.first_predecessor(b)
          next if !p || p == @cfg.entry || @cfg.successors_length(p) != 1

          # add the statements in b to the end of p
          p.stmt_list.concat(b.stmt_list)

          # make each successor of b a successor of p
          @cfg.each_successor(b) do |s|
            @cfg.add_edge(Graph::Edge.new(p, s))
          end

          # whatever p's exit was, it must not be important now because
          # we've merged its only successor into it
          p.exit = b.exit

          # remove b from the graph
          @cfg.delete_node(b)
        end
      end
    end
  end
end
