# typed: strict
require "sorbet-runtime"
require_relative "../graph"
require_relative "analysis"
require_relative "bb"

class Analysis::CFG < Graph
  extend T::Sig
  extend T::Generic

  include Analysis

  Node = type_member { { fixed: BB } }

  # The number used by the ENTRY block in any CFG.
  ENTRY = -1
  # The number used by the EXIT block in any CFG.
  EXIT = -2

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
  def initialize(block_list)
    super()

    @label_map = T.let(Hash.new, T::Hash[String, BB])
    @entry = T.let(BB.new(ENTRY, stmt_list: []), BB)
    @exit = T.let(BB.new(EXIT, stmt_list: []), BB)

    compute_graph(block_list)
  end

  sig { params(block: T.proc.params(arg0: BB).void).void }
  # Alias for Graph's +each_node+ method.
  def each_block(&block)
    each_node(&block)
  end

  sig { params(block: BB).void }
  # Add a basic block to the CFG.
  #
  # @param [BB] block The basic block to add.
  def add_block(block)
    @nodes.push(block)
    if block.entry and block.entry.is_a?(IL::Label)
      @label_map[T.unsafe(block.entry).name] = block
    end
  end

  sig { returns(Integer) }
  # Find the maximum block ID in the graph. Requires an O(n) search.
  #
  # @return [Integer] The maximum block ID.
  def max_block_id
    max = -1 # also = to ENTRY so be careful
    each_block { |b|
      if b.id > max then max = b.id end
    }
    return max
  end

  private

  sig { params(block_list: T::Array[BB]).void }
  def compute_graph(block_list)
    # just in case this gets run more than once
    @nodes.clear
    @edges.clear
    @predecessors.clear
    @successors.clear

    # add all blocks to the graph nodes
    block_list.each { |b|
      add_block(b)
    }

    # connect blocks into graph nodes
    block_list.each { |b|
      last = b.stmt_list[-1]
      if not last then next end

      # create edge for jump
      if last.is_a?(IL::Jump)
        # find block that jump is targeting
        successor = @label_map[last.target]
        if not successor # this is unlikely but I think possible
          raise("CFG attempted to build edge to label that doesn't exist: \"#{last.target}\"")
        end

        # create an edge to the target block
        create_edge(b, successor)

        # if jump is NOT conditional then stop after creating this edge
        if last.class == IL::Jump
          next
        end
      end

      # create edge to next block
      following = block_list[b.id + 1]
      if following
        create_edge(b, following)
      else # reached the end, point to exit
        create_edge(b, @exit)
      end
    }

    # create edge from entry to first block
    first_block = @nodes[0]
    if not first_block
      first_block = @exit
    end
    create_edge(entry, first_block)

    # add entry and exit block nodes to graph
    @nodes.insert(0, @entry)
    @nodes.push(@exit)
  end
end
