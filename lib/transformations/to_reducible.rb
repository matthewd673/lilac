# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "securerandom"
require_relative "../pass"
require_relative "../graph"
require_relative "../analysis/analysis"
require_relative "../analysis/cfg"

module Lilac
  module Transformations
    # The ToReducible pass transforms an irreducible CFG into a reducible CFG.
    # It is based on the algorithm described in the following paper:
    #   Johan Janssen and Henk Corporaal. 1997. Making graphs reducible with
    #   controlled node splitting. ACM Trans. Program. Lang. Syst. 19, 6
    #   (Nov. 1997), 1031–1052. https://doi.org/10.1145/267959.269971
    class ToReducible < Pass
      extend T::Sig

      include Analysis

      sig { override.returns(String) }
      def self.id
        "to_reducible"
      end

      sig { override.returns(String) }
      def self.description
        "Transform an irreducible CFG into a reducible CFG"
      end

      sig { params(cfg: CFG).void }
      # Construct a new ToReducible pass.
      #
      # @param [Analysis::CFG] cfg The CFG to transform.
      def initialize(cfg)
        @cfg = cfg

        @label_ct = T.let(0, Integer)
      end

      sig { override.void }
      def run!
        @label_ct = 0

        # TODO: this is very rudimentary node splitting, not CNS
        @cfg.each_node do |b|
          # split all nodes with more than 1 predecessor
          if @cfg.predecessors_length(b) > 1
            split_node(b)
          end
        end
      end

      private

      sig { params(node: BB).void }
      def split_node(node)
        @cfg.each_incoming(node) do |i|
          p = i.from # predecessor

          # rename the node's label (even if it didn't have one before)
          new_entry = IL::Label.new(SecureRandom.uuid)

          # create a copy of the node
          new_node = BB.new(SecureRandom.uuid,
                            entry: new_entry,
                            exit: node.exit,
                            stmt_list: node.stmt_list,
                            true_branch: node.true_branch)
          @cfg.add_node(new_node)

          # add incoming edge to new node
          @cfg.add_edge(Graph::Edge.new(p, new_node))

          # also copy all outgoing edges
          @cfg.each_outgoing(node) do |o|
            to = o.to
            if to == node
              to = new_node
            end

            @cfg.add_edge(Graph::Edge.new(new_node, to))
          end

          # if predecessor jumps to this node, replace label name with new one
          if p.exit
            T.unsafe(p.exit).target = new_entry.name
          end
        end

        # delete original node
        @cfg.delete_node(node)
      end
    end
  end
end
