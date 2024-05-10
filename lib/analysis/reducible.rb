# typed: strict
# frozen_string_literal: true

require_relative "cfg"

module Lilac
  module Analysis
    # Determine if a CFG is reducible.
    class Reducible
      extend T::Sig
      extend T::Generic

      include Analysis

      sig { params(cfg: CFG).void }
      # Construct a new Reducible analysis.
      #
      # @param [CFG] cfg The CFG to run the analysis on.
      def initialize(cfg)
        # not important that it stays a CFG class
        @cfg = T.let(cfg.clone, Graph[BB])
      end

      sig { returns(T::Boolean) }
      # Run the analysis to determine if the CFG is reducible.
      #
      # @return [T::Boolean] True if the CFG is reducible. False otherwise.
      def run
        # run until no more transformations can be applied
        applied = T.let(true, T::Boolean)
        while applied
          applied = false
          # T1: remove all self-edges on a node
          @cfg.each_node do |n|
            @cfg.each_outgoing(n) do |o|
              next unless o.to == n

              @cfg.delete_edge(o)
              applied = true
              break
            end
          end

          # T2: if n has a single predecessor m, fold n into m
          @cfg.each_node do |n|
            next unless @cfg.predecessors_length(n) == 1

            m = @cfg.each_predecessor(n) { |n| break n }
            merge_nodes(n, T.unsafe(m))
            applied = true
          end
        end

        @cfg.nodes_length == 1
      end

      private

      sig { params(n: Analysis::BB, m: Analysis::BB).void }
      def merge_nodes(n, m)
        # remove edge from m -> n
        mn_edge = @cfg.find_edge(m, n)
        unless mn_edge
          raise "No edge m -> n found, cannot merge"
        end

        @cfg.delete_edge(mn_edge)

        # many any edges originating from n originate from m
        @cfg.each_outgoing(n) do |o|
          new_edge = Graph::Edge.new(m, o.to)
          @cfg.delete_edge(o)
          @cfg.add_edge(new_edge)
        end

        # if there are now multiple edges from m to some node, remvoe them
        seen_to = Set.new
        @cfg.each_outgoing(m) do |o|
          # duplicate
          if seen_to.include?(o.to)
            @cfg.delete_edge(o)
          end

          seen_to.add(o.to)
        end

        # remove n
        @cfg.delete_node(n)
      end
    end
  end
end
