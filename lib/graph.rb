# typed: strict
require "sorbet-runtime"

# A Graph is a generic data structure representing a graph with nodes and
# edges.
class Graph
  extend T::Sig
  extend T::Generic

  Node = type_member {{ upper: Object }}

  # An Edge is a generic data structure representing a directed edge between
  # two nodes in a graph.
  class Edge
    extend T::Sig
    extend T::Generic

    Node = type_member {{ upper: Object }}

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
      if other.class != Edge
        return false
      end

      return (to.eql?(other.to) and from.eql?(other.from))
    end
  end

  sig { void }
  # Construct a new Graph.
  def initialize
    @nodes = T.let([], T::Array[Node])
    @edges = T.let([], T::Array[Edge[Node]])

    @incoming = T.let(Hash.new, T::Hash[Node, T::Set[Edge[Node]]])
    @outgoing = T.let(Hash.new, T::Hash[Node, T::Set[Edge[Node]]])
  end

  sig { params(block: T.proc.params(arg0: Node).void).void }
  def each_node(&block)
    @nodes.each(&block)
  end

  sig { params(block: T.proc.params(arg0: Edge[Node]).void).void }
  def each_edge(&block)
    @edges.each(&block)
  end

  sig { params(node: Node, block: T.proc.params(arg0: Edge[Node]).void).void }
  def each_incoming(node, &block)
    incoming = @incoming[node]
    if not incoming
      []
    else
      incoming.each(&block)
    end
  end

  sig { params(node: Node, block: T.proc.params(arg0: Edge[Node]).void).void }
  def each_outgoing(node, &block)
    outgoing = @outgoing[node]
    if not outgoing
      []
    else
      outgoing.each(&block)
    end
  end

  sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
  def each_predecessor(node, &block)
    each_incoming(node) { |e|
      yield e.from
    }
  end

  sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
  def each_successor(node, &block)
    each_outgoing(node) { |e|
      yield e.to
    }
  end

  sig { params(node: Node).returns(Integer) }
  # Get the number of predecessors of a given node in the graph.
  #
  # @param [Node] node The node for which the predecessors will be counted.
  # @return [Integer] The number of predecessors of the node. If the node is
  #   not in the graph this will be +0+.
  def predecessors_length(node)
    incoming = @incoming[node]
    if not incoming
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
    if not outgoing
      0
    else
      outgoing.length
    end
  end

  sig { params(node: Node).void }
  def add_node(node)
    @nodes.push(node)
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
    if not @outgoing[edge.from]
      @outgoing[edge.from] = Set[]
    end
    T.unsafe(@outgoing[edge.from]).add(edge)

    # add this edge to "to"'s incoming
    if not @incoming[edge.to]
      @incoming[edge.to] = Set[]
    end
    T.unsafe(@incoming[edge.to]).add(edge)
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
    if outgoing # should never be nil
      outgoing.delete(edge)
    end

    # remove this edge from "to"'s incoming
    incoming = @incoming[edge.to]
    if incoming # should never be nil
      incoming.delete(edge)
    end
  end
end
