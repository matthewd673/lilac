# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"

module Lilac
  # A Graph is a generic data structure representing a graph with nodes and
  # directed edges.
  class Graph
    extend T::Sig
    extend T::Generic

    Node = type_member { { upper: Object } }

    # An Edge is a generic data structure representing a directed edge between
    # two nodes in a graph.
    class Edge
      extend T::Sig
      extend T::Generic

      Node = type_member { { upper: Object } }

      sig { returns(Node) }
      attr_reader :from

      sig { returns(Node) }
      attr_reader :to

      sig { params(from: Node, to: Node).void }
      # Construct a new Edge.
      #
      # @param [Node] from The node that the edge originates from.
      # @param [Node] to The node that the edge terminates at.
      def initialize(from, to)
        @from = from
        @to = to
      end

      sig { params(other: T.untyped).returns(T::Boolean) }
      def eql?(other)
        if other.class != self.class
          return false
        end

        to.eql?(other.to) && from.eql?(other.from)
      end

      sig { returns(String) }
      def to_s
        "#{from} -> #{to}"
      end
    end

    sig { void }
    # Construct a new Graph.
    def initialize
      @nodes = T.let([], T::Array[Node])
      @edges = T.let([], T::Array[Edge[Node]])

      @incoming = T.let({}, T::Hash[Node, T::Set[Edge[Node]]])
      @outgoing = T.let({}, T::Hash[Node, T::Set[Edge[Node]]])
    end

    sig { params(block: T.proc.params(arg0: Node).void).void }
    # Iterate over every node in the graph.
    def each_node(&block)
      @nodes.each(&block)
    end

    sig { params(block: T.proc.params(arg0: Edge[Node]).void).void }
    # Iterate over every edge in the graph.
    def each_edge(&block)
      @edges.each(&block)
    end

    sig { returns(Integer) }
    def nodes_length
      @nodes.length
    end

    sig { returns(Integer) }
    def edges_length
      @edges.length
    end

    sig { params(node: Node, block: T.proc.params(arg0: Edge[Node]).void).void }
    # Iterate over every incoming edge of a given node in the graph.
    # Incoming edges are edges that terminate at the node.
    #
    # @param [Node] node The node to iterate for.
    def each_incoming(node, &block)
      incoming = @incoming[node]
      if !incoming
        []
      else
        incoming.each(&block)
      end
    end

    sig { params(node: Node, block: T.proc.params(arg0: Edge[Node]).void).void }
    # Iterate over every outgoing edge of a given node in the graph.
    # Outgoing edges are edges that originate at the node.
    #
    # @param [Node] node The node to iterate for.
    def each_outgoing(node, &block)
      outgoing = @outgoing[node]
      if !outgoing
        []
      else
        outgoing.each(&block)
      end
    end

    sig { params(node: Node).returns(Integer) }
    def incoming_length(node)
      incoming = @incoming[node]
      if !incoming
        0
      else
        incoming.length
      end
    end

    sig { params(node: Node).returns(Integer) }
    def outgoing_length(node)
      outgoing = @outgoing[node]
      if !outgoing
        0
      else
        outgoing.length
      end
    end

    sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
    # Iterate over every predecessor of a given node in the graph.
    #
    # @param [Node] node The node to iterate for.
    def each_predecessor(node, &block)
      each_incoming(node) do |e|
        yield e.from
      end
    end

    sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
    # Iterate over every successor of a given node in the graph.
    #
    # @param [Node] node The node to iterate for.
    def each_successor(node, &block)
      each_outgoing(node) do |e|
        yield e.to
      end
    end

    sig { params(node: Node).returns(Integer) }
    # Get the number of predecessors of a given node in the graph.
    #
    # @param [Node] node The node for which the predecessors will be counted.
    # @return [Integer] The number of predecessors of the node. If the node is
    #   not in the graph this will be +0+.
    def predecessors_length(node)
      incoming = @incoming[node]
      if !incoming
        0
      else
        incoming.length
      end
    end

    sig { params(node: Node).returns(Integer) }
    # Get the number of successors of a given node in the graph.
    #
    # @param [Node] node The node for which the successors will be counted.
    # @return [Integer] The number of successors of the node. If the node is
    #   not in the graph this will be +0+.
    def successors_length(node)
      outgoing = @outgoing[node]
      if !outgoing
        0
      else
        outgoing.length
      end
    end

    sig { params(node: Node).void }
    # Add a node to the graph.
    #
    # @param [Node] node The node to add.
    def add_node(node)
      @nodes.push(node)
    end

    sig { params(node: Node).void }
    # Delete a node from the graph. Its incoming and outgoing edges will also
    # be deleted from the graph.
    #
    # @param [Node] node The node to delete.
    def delete_node(node)
      @nodes.delete(node)

      each_outgoing(node) do |o|
        delete_edge(o)
      end

      each_incoming(node) do |i|
        delete_edge(i)
      end
    end

    sig { params(edge: Edge[Node]).void }
    # Add an Edge to the Graph's edge list. The nodes will also be
    # added to the appropriate successors and predecessors lists. This should
    # be used instead of manually pushing Edges.
    #
    # @param [Edge] edge The edge to add.
    def add_edge(edge)
      @edges.push(edge)

      # add this edge to "from"'s outgoing
      unless @outgoing[edge.from]
        @outgoing[edge.from] = Set[]
      end
      @outgoing[edge.from]&.add(edge)

      # add this edge to "to"'s incoming
      unless @incoming[edge.to]
        @incoming[edge.to] = Set[]
      end
      @incoming[edge.to]&.add(edge)
    end

    sig { params(edge: Edge[Node]).void }
    # Remove an Edge from the edge list. This will also appropriately
    # update the successors and predecessors lists.
    #
    # @param [Edge[Node]] edge The Edge to remove from the graph
    # (with a shallow check).
    def delete_edge(edge)
      @edges.delete(edge)

      # remove this edge from "from"'s outgoing
      outgoing = @outgoing[edge.from]
      # should never be nil
      outgoing&.delete(edge)

      # remove this edge from "to"'s incoming
      incoming = @incoming[edge.to]
      # should never be nil
      incoming&.delete(edge)
    end

    sig { params(from: Node, to: Node).returns(T.nilable(Edge[Node])) }
    def find_edge(from, to)
      each_outgoing(from) do |o|
        if o.to == to
          return o
        end
      end

      nil
    end

    sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
    def postorder_traversal(node, &block)
      postorder_traversal_helper(node, Set.new, &block)
    end

    sig { params(node: Node).returns(T::Hash[Analysis::BB, Integer]) }
    def postorder_numbering(node)
      numbering = {}
      i = 0
      postorder_traversal(node) do |n|
        numbering[n] = i
        i += 1
      end
      numbering
    end

    sig { params(node: Node).returns(T::Hash[Analysis::BB, Integer]) }
    def reverse_postorder_numbering(node)
      numbering = {}
      i = @nodes.length - 1
      postorder_traversal(node) do |n|
        numbering[n] = i
        i -= 1
      end
      numbering
    end

    sig { returns(Graph[Node]) }
    def clone
      new_graph = Graph.new

      @nodes.each do |n|
        new_graph.add_node(n)
      end
      @edges.each do |e|
        new_graph.add_edge(e)
      end

      new_graph
    end

    private

    sig do
      params(node: Node,
             seen: T::Set[Node],
             block: T.proc.params(arg0: Node).void)
        .void
    end
    def postorder_traversal_helper(node, seen, &block)
      if seen.include?(node)
        return
      end

      seen.add(node)

      each_successor(node) do |s|
        postorder_traversal_helper(s, seen, &block)
      end

      yield node
    end
  end
end
