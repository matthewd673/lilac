# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../graph"
require_relative "bb"

module Lilac
  module Analysis
    # A CFG is a type of +Graph+ that represents control flow graphs.
    class CFG < Graph
      extend T::Sig
      extend T::Generic

      include Analysis

      Node = type_member { { fixed: BB } }

      # The ID used by the ENTRY block in any CFG.
      ENTRY = "ENTRY"
      # The ID used by the EXIT block in any CFG.
      EXIT = "EXIT"

      sig { returns(BB) }
      # The ENTRY block in this CFG.
      #
      # @return [BB::Block] The ENTRY block object in this CFG.
      attr_reader :entry

      sig { returns(BB) }
      # The EXIT block in this CFG.
      #
      # @return [BB::Block] The EXIT block object in this CFG.
      attr_reader :exit

      sig { params(block_list: T::Array[BB]).void }
      # Construct a new CFG from a list of basic blocks.
      #
      # @param [T::Array[BB]] block_list The list of basic blocks which will be
      #   the nodes of this CFG.
      def initialize(block_list)
        super()

        @label_map = T.let({}, T::Hash[String, BB])
        @entry = T.let(BB.new(ENTRY, stmt_list: []), BB)
        @exit = T.let(BB.new(EXIT, stmt_list: []), BB)

        compute_graph(block_list)
      end

      sig { params(block: T.proc.params(arg0: BB).void).void }
      # Alias for Graph's +each_node+ method.
      def each_block(&block)
        each_node(&block)
      end

      sig { params(node: BB).void }
      # Add a basic block to the CFG.
      #
      # @param [BB] node The basic block to add.
      def add_node(node)
        @nodes.push(node)
        return unless node.entry&.is_a?(IL::Label)

        @label_map[T.unsafe(node.entry).name] = node
      end

      private

      sig { params(block_list: T::Array[BB]).void }
      def compute_graph(block_list)
        # just in case this gets run more than once
        @nodes.clear
        @edges.clear
        @incoming.clear
        @outgoing.clear

        # add all blocks to the graph nodes
        block_list.each do |b|
          add_node(b)
        end

        # connect blocks into graph nodes
        block_list.each_with_index do |b, i|
          # create edge for block exit (some IL::Jump)
          if b.exit
            jump = T.unsafe(b.exit) # to placate Sorbet below

            # find block that jump is targeting
            successor = @label_map[jump.target]
            unless successor # this is unlikely but I think possible
              raise "CFG attempted to build edge to label that doesn't exist: "\
                    "\"#{jump.target}\""
            end

            # create an edge to the target block
            # if jump IS conditional then the edge must be (and we can easily
            # check if a jump is conditional based on its class)
            successor.true_branch = jump.class != IL::Jump
            add_edge(Edge.new(b, successor))

            # if jump is NOT conditional then stop after creating this edge
            if jump.instance_of?(IL::Jump)
              next
            end
          end

          # create edge to next block
          following = block_list[i + 1]
          if following
            following.true_branch = false
            add_edge(Edge.new(b, following))
          else # reached the end, point to exit
            @exit.true_branch = false
            add_edge(Edge.new(b, @exit))
          end
        end

        # create edge from entry to first block
        first_block = @nodes[0]
        first_block ||= @exit
        first_block.true_branch = false
        add_edge(Edge.new(entry, first_block))

        # add entry and exit block nodes to graph
        @nodes.insert(0, @entry)
        @nodes.push(@exit)
      end
    end
  end
end
