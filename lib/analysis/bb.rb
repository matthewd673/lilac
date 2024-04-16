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

  sig { returns(T.nilable(IL::Label)) }
  # The Label that marks the entry of the block (if one exists)
  attr_reader :entry

  sig { returns(T.nilable(IL::Jump)) }
  # The Jmp that marks the exit of the block (if one exists)
  attr_reader :exit

  sig { returns(T::Array[IL::Statement]) }
  # The Statements in the block.
  attr_reader :stmt_list

  sig { params(id: Integer,
               entry: T.nilable(IL::Label),
               exit: T.nilable(IL::Jump),
               stmt_list: T::Array[IL::Statement]).void }
  def initialize(id, entry: nil, exit: nil, stmt_list: [])
    @id = id
    @entry = entry
    @exit = exit
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

    str = "BB##{id_str}"

    if @entry or @exit
      str += " ("
      if @entry
        str += "entry=#{@entry.class} '#{@entry.name}', "
      end
      if @exit
        str += "exit=#{@exit.class} '#{@exit.to_s}'"
      end
      str.chomp!(", ")
      str += ")"
    end

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
      b.stmt_list.each { |s|
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
    current_entry = T.let(nil, T.nilable(IL::Label))

    stmt_list.each { |s|
      # mark beginning of a block
      if s.is_a?(IL::Label)
        # push previous block onto list (exit is nil)
        blocks.push(Analysis::BB.new(blocks.length,
                                     entry: current_entry,
                                     stmt_list: block_stmts))
        block_stmts = []
        current_entry = s
      end

      # don't push labels or jumps
      # they belong in @entry or @exit
      if not (s.is_a?(IL::Label) or s.is_a?(IL::Jump))
        block_stmts.push(s)
      end

      # mark end of a block
      if s.is_a?(IL::Jump)
        blocks.push(Analysis::BB.new(blocks.length,
                                     entry: current_entry,
                                     exit: s,
                                     stmt_list: block_stmts))
        block_stmts = []
        current_entry = nil
      end
    }

    # scoop up stragglers
    if not block_stmts.empty?
      blocks.push(Analysis::BB.new(blocks.length,
                                   entry: current_entry,
                                   stmt_list: block_stmts))
    end

    return blocks
  end
end
