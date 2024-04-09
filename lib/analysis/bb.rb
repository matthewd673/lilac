# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "cfg"
require_relative "../il"

# A BB is a data structure representing a basic block.
class Analysis::BB
  extend T::Sig

  sig { returns(Integer) }
  # The unique ID of the block.
  attr_reader :id

  sig { params(id: Integer, stmt_list: T::Array[IL::Statement]).void }
  def initialize(id, stmt_list)
    @id = id
    @stmt_list = stmt_list
  end

  sig { returns(Integer) }
  # Get the number of Statements in the block.
  # @return [Integer] The length of the block's Statement list.
  def length
    @stmt_list.length
  end

  sig { returns(T::Boolean) }
  # Determines if the block is empty.
  # @return [T::Boolean] True if there are no Statements in the block's
  #   Statement list.
  def empty?
    @stmt_list.empty?
  end

  sig { params(block: T.proc.params(arg0: IL::Statement).void).void }
  def each_stmt(&block)
    @stmt_list.each(&block)
  end

  sig { params(block: T.proc.params(arg0: IL::Statement, arg1: Integer).void)
          .void }
  def each_stmt_with_index(&block)
    @stmt_list.each_with_index(&block)
  end

  sig { returns(T.nilable(IL::Statement)) }
  # Get the first Statement in the block.
  # @return [T.nilable(IL::Statement)] The first Statement in the block.
  #   If the block is empty this will be nil.
  def first_stmt
    if @stmt_list.empty? then return nil end
    return @stmt_list[0]
  end

  sig { returns(T.nilable(IL::Statement)) }
  # Get the last Statement in the block.
  # @return [T.nilable(IL::Statement)] The last Statement in the block.
  #   If the block is empty this will be nil.
  def last_stmt
    if @stmt_list.empty? then return nil end
    return @stmt_list[-1]
  end

  sig { params(stmt: IL::Statement).void }
  def unshift_stmt(stmt)
    @stmt_list.unshift(stmt)
  end

  sig { returns(String) }
  # Convert the block, and its Statements, to a String.
  # @return [String] A String representation of the block.
  def to_s
    id_str = id.to_s
    if id == Analysis::CFG::ENTRY
      id_str = "ENTRY"
    elsif id == Analysis::CFG::EXIT
      id_str = "EXIT"
    end
    str = "[#{id_str}]\n"
    each_stmt { |s|
      str += "  #{s.to_s}\n"
    }
    return str
  end

  sig { params(other: Analysis::BB).returns(T::Boolean) }
  # Returns true if two BBs are equal. BBs are considered equal if they have
  # the same ID.
  def eql?(other)
    return (id == other.id)
  end

  sig { params(stmt_list: T::Array[IL::Statement])
          .returns(T::Array[Analysis::BB]) }
  # Create a list of basic blocks for the given statement list.
  # @param [T::Array[IL::Statement]] stmt_list The statement list to
  #   create blocks from.
  # @return [T::Array[Analysis::BB]] A list of basic blocks in
  #   the statement list.
  def self.from_stmt_list(stmt_list)
    return create_blocks(stmt_list)
  end

  sig { params(bb_list: T::Array[Analysis::BB])
          .returns(T::Array[IL::Statement]) }
  def self.to_stmt_list(bb_list)
    stmt_list = []
    bb_list.each { |b|
      b.each_stmt { |s|
        stmt_list.push(s)
      }
    }
    return stmt_list
  end

  private

  sig { params(stmt_list: T::Array[IL::Statement])
          .returns(T::Array[Analysis::BB]) }
  def self.create_blocks(stmt_list)
    blocks = []
    block_stmts = []

    stmt_list.each { |s|
      # mark beginning of a block
      if s.is_a?(IL::Label) and not block_stmts.empty?
        blocks.push(Analysis::BB.new(blocks.length, block_stmts))
        block_stmts = []
      end

      block_stmts.push(s)

      # mark end of a block
      if s.is_a?(IL::Jump) # block will never be empty due to above push
        blocks.push(Analysis::BB.new(blocks.length, block_stmts))
        block_stmts = []
      end
    }

    # scoop up stragglers
    if not block_stmts.empty?
      blocks.push(Analysis::BB.new(blocks.length, block_stmts))
    end

    return blocks
  end
end
