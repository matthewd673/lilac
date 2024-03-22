# typed: strict
require "sorbet-runtime"
require_relative "analysis"
require_relative "../il"

# The BB module contains a data structure for basic blocks and functions
# to create basic blocks from IL Statements.
module Analysis::BB
  extend T::Sig

  # A Block is a data structure for a single basic block.
  class Block
    extend T::Sig

    sig { returns(Integer) }
    # The unique number of the block.
    attr_reader :number

    sig { params(number: Integer, stmt_list: T::Array[IL::Statement]).void }
    def initialize(number, stmt_list)
      @number = number
      @stmt_list = stmt_list
    end

    sig { returns(Integer) }
    # Get the number of Statements in the Block.
    # @return [Integer] The length of the Block's Statement list.
    def length
      @stmt_list.length
    end

    sig { returns(T::Boolean) }
    # Determines if the block is empty.
    # @return [T::Boolean] True if there are no Statements in the Block's
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
    # @return [T.nilable(IL::Statement)] The first Statement in the Block.
    #   If the Block is empty this will be nil.
    def first_stmt
      if @stmt_list.empty? then return nil end
      return @stmt_list[0]
    end

    sig { returns(T.nilable(IL::Statement)) }
    # Get the last Statement in the block.
    # @return [T.nilable(IL::Statement)] The last Statement in the Block.
    #   If the Block is empty this will be nil.
    def last_stmt
      if @stmt_list.empty? then return nil end
      return @stmt_list[-1]
    end

    sig { returns(String) }
    # Convert the Block, and its Statements, to a String.
    # @return [String] A String representation of the Block.
    def to_s
      str = "[BLOCK (len=#{length})]\n"
      each_stmt { |s|
        str += s.to_s + "\n"
      }
      return str
    end
  end

  sig { params(program: IL::Program).returns(T::Array[Block]) }
  # Create a list of basic blocks for the given Program.
  # @param [IL::Program] program The Program to create blocks from.
  # @return [T::Array[Block]] A list of basic blocks.
  def self.create_blocks(program)
    blocks = []
    stmt_list = []

    # TODO: adapt to work with functions
    program.item_list.each { |i|
      # mark beginning of a block
      if i.is_a?(IL::Label) and not stmt_list.empty?
        blocks.push(Block.new(blocks.length, stmt_list))
        stmt_list = []
      end

      stmt_list.push(i)

      # mark end of a block
      if i.is_a?(IL::Jump) # block will never be empty due to above push
        blocks.push(Block.new(blocks.length, stmt_list))
        stmt_list = []
      end
    }

    if not stmt_list.empty?
      blocks.push(Block.new(blocks.length, stmt_list))
    end

    return blocks
  end
end
