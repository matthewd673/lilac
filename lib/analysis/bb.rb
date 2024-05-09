# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "securerandom"
require_relative "analysis"
require_relative "../il"

module Analysis
  # A BB is a data structure representing a basic block.
  class BB
    extend T::Sig

    sig { returns(String) }
    # The unique ID of the block.
    attr_reader :id

    sig { returns(T.nilable(IL::Label)) }
    # The Label that marks the entry of the block (if one exists)
    attr_accessor :entry

    sig { returns(T.nilable(IL::Jump)) }
    # The Jump that marks the exit of the block (if one exists)
    attr_accessor :exit

    sig { returns(T::Array[IL::Statement]) }
    # The Statements in the block.
    attr_reader :stmt_list

    sig { returns(T::Boolean) }
    # Determines if a block is visited by the true branch of a
    # conditional jump.
    attr_accessor :true_branch

    sig do
      params(id: String,
             entry: T.nilable(IL::Label),
             exit: T.nilable(IL::Jump),
             stmt_list: T::Array[IL::Statement],
             true_branch: T::Boolean).void
    end
    def initialize(id, entry: nil, exit: nil, stmt_list: [], true_branch: false)
      @id = id
      @entry = entry
      @exit = exit
      @stmt_list = stmt_list
      @true_branch = true_branch
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
      if id == -1 # hardcoded and ugly
        id_str = "ENTRY"
      elsif id == -2 # hardcoded and ugly
        id_str = "EXIT"
      end

      str = "BB##{id_str}"

      if @entry || @exit
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

      str
    end

    sig { params(other: Analysis::BB).returns(T::Boolean) }
    # Returns true if two BBs are equal. BBs are considered equal if they have
    # the same ID.
    def eql?(other)
      unless other.class == BB
        return false
      end

      id.eql?(other.id)
    end

    sig do
      params(stmt_list: T::Array[IL::Statement])
        .returns(T::Array[Analysis::BB])
    end
    # Create a list of basic blocks for the given statement list.
    # @param [T::Array[IL::Statement]] stmt_list The statement list to
    #   create blocks from.
    # @return [T::Array[Analysis::BB]] A list of basic blocks in
    #   the statement list.
    def self.from_stmt_list(stmt_list)
      create_blocks(stmt_list)
    end

    sig do
      params(bb_list: T::Array[Analysis::BB])
        .returns(T::Array[IL::Statement])
    end
    def self.to_stmt_list(bb_list)
      stmt_list = []
      bb_list.each do |b|
        b.stmt_list.each do |s|
          stmt_list.push(s)
        end
      end
      stmt_list
    end

    private

    sig do
      params(stmt_list: T::Array[IL::Statement])
        .returns(T::Array[Analysis::BB])
    end
    def self.create_blocks(stmt_list)
      blocks = []
      block_stmts = []
      current_entry = T.let(nil, T.nilable(IL::Label))

      stmt_list.each do |s|
        # mark beginning of a block
        if s.is_a?(IL::Label)
          # push previous block onto list (exit is nil)
          unless block_stmts.empty? && !current_entry
            blocks.push(Analysis::BB.new(SecureRandom.uuid,
                                         entry: current_entry,
                                         stmt_list: block_stmts))
            block_stmts = []
          end
          current_entry = s
        end

        # don't push labels or jumps
        # they belong in @entry or @exit
        unless s.is_a?(IL::Label) || s.is_a?(IL::Jump)
          block_stmts.push(s)
        end

        # mark end of a block
        next unless s.is_a?(IL::Jump)

        blocks.push(Analysis::BB.new(SecureRandom.uuid,
                                     entry: current_entry,
                                     exit: s,
                                     stmt_list: block_stmts))
        block_stmts = []
        current_entry = nil
      end

      # scoop up stragglers
      if !block_stmts.empty? || current_entry
        blocks.push(Analysis::BB.new(SecureRandom.uuid,
                                     entry: current_entry,
                                     stmt_list: block_stmts))
      end

      blocks
    end
  end
end
