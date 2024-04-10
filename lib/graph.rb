# typed: strict
require "sorbet-runtime"

# A Graph is a generic data structure representing a graph with nodes and
# edges.
class Graph
  extend T::Sig
  extend T::Generic

  Node = type_member

  # An Edge is a generic data structure representing a directed edge between
  # two nodes in a graph.
  class Edge
    extend T::Sig
    extend T::Generic

    Node = type_member

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
  end

  sig { void }
  # Construct a new Graph.
  def initialize
    @nodes = T.let([], T::Array[Node])
    @edges = T.let([], T::Array[Edge[Node]])

    @predecessors = T.let(Hash.new, T::Hash[Node, T::Set[Node]])
    @successors = T.let(Hash.new, T::Hash[Node, T::Set[Node]])
  end

  sig { params(block: T.proc.params(arg0: Node).void).void }
  def each_node(&block)
    @nodes.each(&block)
  end

  sig { params(block: T.proc.params(arg0: Edge[Node]).void).void }
  def each_edge(&block)
    @edges.each(&block)
  end

  sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
  def each_predecessor(node, &block)
    preds = @predecessors[node]
    if not preds
      []
    else
      preds.each(&block)
    end
  end

  sig { params(node: Node, block: T.proc.params(arg0: Node).void).void }
  def each_successor(node, &block)
    succs = @successors[node]
    if not succs
      []
    else
      succs.each(&block)
    end
  end

  sig { params(node: Node).returns(Integer) }
  # Get the number of predecessors of a given node in the graph.
  #
  # @param [Node] node The node for which the predecessors will be counted.
  # @return [Integer] The number of predecessors of the node. If the node is
  #   not in the graph this will be +0+.
  def predecessors_length(node)
    preds = @predecessors[node]
    if not preds
      0
    else
      preds.length
    end
  end

  sig { params(node: Node).returns(Integer) }
  # Get the number of successors of a given node in the graph.
  #
  # @param [Node] node The node for which the successors will be counted.
  # @return [Integer] The number of successors of the node. If the node is
  #   not in the graph this will be +0+.
  def successors_length(node)
    succs = @successors[node]
    if not succs
      0
    else
      succs.length
    end
  end

  sig { params(from: Node, to: Node).void }
  # Create a new Edge and add it to the edge list. The nodes will also be
  # added to the appropriate successors and predecessors lists. This should
  # be used instead of manually creating and pushing Edges.
  #
  # @param [Node] from The node that the edge originates from.
  # @param [Node] to The node that the edge terminates at.
  def create_edge(from, to)
    edge = Edge.new(from, to)
    @edges.push(edge)

    # add "to" to "from"s successors
    if not @successors[from]
      @successors[from] = Set[]
    end
    T.unsafe(@successors[from]).add(to)

    # add "from" to "to"s predecessors
    if not @predecessors[to]
      @predecessors[to] = Set[]
    end
    T.unsafe(@predecessors[to]).add(from)
  end

  sig { params(edge: Edge[Node]).void }
  # Remove an Edge from the edge list. This will also appropriately
  # update the successors and predecessors lists.
  #
  # @param [Edge[Node]] edge The Edge to remove from the graph
  # (with a shallow check).
  def delete_edge(edge)
    @edges.delete(edge)

    # remove "to" from "from" successors
    succs = @successors[edge.from]
    if succs # should never be nil
      succs.delete(edge.to)
    end

    # remove "from" from "to" predecessors
    preds = @predecessors[edge.to]
    if preds # should never be nil
      preds.delete(edge.from)
    end
  end
end
