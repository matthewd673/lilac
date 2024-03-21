# typed: strict
require "sorbet-runtime"
require "set"
require_relative "analysis"
require_relative "bb"

class Analysis::CFG
  extend T::Sig

  include Analysis

  class Edge
    extend T::Sig

    include Analysis

    sig { returns(BB::Block) }
    attr_reader :from
    sig { returns(BB::Block) }
    attr_reader :to

    sig { params(from: BB::Block, to: BB::Block).void }
    def initialize(from, to)
      @from = from
      @to = to
    end
  end

  # The number used by the ENTRY block in any CFG.
  ENTRY = -1
  # The number used by the EXIT block in any CFG.
  EXIT = -2

  sig { returns(BB::Block) }
  # The ENTRY block in this CFG.
  #
  # @return [BB::Block] The ENTRY block object in this CFG.
  attr_reader :entry

  sig { returns(BB::Block) }
  # The EXIT block in this CFG.
  #
  # @return [BB::Block] The EXIT block object in this CFG.
  attr_reader :exit

  sig { params(block_list: T::Array[BB::Block]).void }
  def initialize(block_list)
    @blocks = T.let([], T::Array[BB::Block])
    @edges = T.let([], T::Array[Edge])

    @predecessors = T.let(Hash.new, T::Hash[Integer, T::Set[BB::Block]])
    @successors = T.let(Hash.new, T::Hash[Integer, T::Set[BB::Block]])

    @entry = T.let(BB::Block.new(ENTRY, []), BB::Block)
    @exit = T.let(BB::Block.new(EXIT, []), BB::Block)

    calculate_graph(block_list)
  end

  sig { params(block: T.proc.params(arg0: BB::Block).void).void }
  def each_block(&block)
    @blocks.each(&block)
  end

  sig { params(block: T.proc.params(arg0: Edge).void).void }
  def each_edge(&block)
    @edges.each(&block)
  end

  sig { params(b_block: BB::Block,
               block: T.proc.params(arg0: BB::Block).void).void }
  def each_predecessor(b_block, &block)
    if not @predecessors[b_block.number]
      return []
    end
    T.unsafe(@predecessors[b_block.number]).each(&block)
  end

  sig { params(b_block: BB::Block,
               block: T.proc.params(arg0: BB::Block).void).void }
  def each_successor(b_block, &block)
    if not @successors[b_block.number]
      return []
    end
    T.unsafe(@successors[b_block.number]).each(&block)
  end

  protected

  sig { params(from: BB::Block, to: BB::Block).void }
  # Create a new Edge and add it to the edge list. The blocks will also be
  # added to the appropriate successors and predecessors lists. This should
  # be used instead of manually creating and pushing Edges.
  #
  # @param [BB::Block] from The Block that the edge originates from.
  # @param [BB::Block] to The Block that the edge terminates at.
  def create_edge(from, to)
    edge = Edge.new(from, to)
    @edges.push(edge)

    # add "to" to "from"s successors
    if not @successors[from.number]
      @successors[from.number] = Set[]
    end
    T.unsafe(@successors[from.number]).push(to)

    # add "from" to "to"s predecessors
    if not @predecessors[to.number]
      @predecessors[to.number] = Set[]
    end
    T.unsafe(@predecessors[to.number]).push(from)
  end

  sig { params(block_list: T::Array[BB::Block]).void }
  def calculate_graph(block_list)
    # just in case this gets run more than once
    @blocks.clear
    @edges.clear

    label_to_block = {} # label name to node beginning with that label

    # remember which labels correspond to which blocks
    block_list.each { |b|
      @blocks.push(b)

      first = b.first_stmt
      if first.is_a?(IL::Label)
        label_to_block[first.name] = b
      end
    }

    # connect blocks into graph nodes
    block_list.each { |b|
      last = b.last_stmt
      if not last then next end

      # create edge for jump
      if last.is_a?(IL::Jump)
        # find block that jump is targeting
        successor = label_to_block[last.target]
        if not successor # this is unlikely but I think possible
          raise("CFG attempted to build edge to label that doesn't exist: \"#{last.target}\"")
        end

        # create an edge to the target block
        @edges.push(Edge.new(b, successor))

        # if jump is NOT conditional then stop after creating this edge
        if last.class == IL::Jump
          next
        end
      end

      # create edge to next block
      following = block_list[b.number + 1]
      if following
        @edges.push(Edge.new(b, following))
      else # reached the end, point to exit
        @edges.push(Edge.new(b, @exit))
      end
    }

    # create edge from entry to first block
    first_block = @blocks[0]
    if not first_block
      first_block = @exit
    end
    @edges.push(Edge.new(@entry, first_block))

    # add entry and exit block nodes to graph
    @blocks.insert(0, @entry)
    @blocks.push(@exit)
  end
end
