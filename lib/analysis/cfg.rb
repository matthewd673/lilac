# typed: strict
require "sorbet-runtime"
require_relative "bb"

class CFG
  extend T::Sig

  sig { returns(BB::Block) }
  attr_reader :entry
  sig { returns(BB::Block) }
  attr_reader :exit

  sig { params(block_list: T::Array[BB::Block]).void }
  def initialize(block_list)
    @blocks = T.let([], T::Array[BB::Block])
    @edges = T.let([], T::Array[Edge])

    @entry = T.let(BB::Block.new(-1, []), BB::Block)
    @exit = T.let(BB::Block.new(-2, []), BB::Block)

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

  class Edge
    extend T::Sig

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

  protected

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
