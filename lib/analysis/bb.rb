# typed: strict
require "sorbet-runtime"
require_relative "../il"

module BB
  extend T::Sig

  class Block
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :number

    sig { params(number: Integer, stmt_list: T::Array[IL::Statement]).void }
    def initialize(number, stmt_list)
      @number = number
      @stmt_list = stmt_list
    end

    sig { returns(Integer) }
    def length
      @stmt_list.length
    end

    sig { returns(T::Boolean) }
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
    def first_stmt
      if @stmt_list.empty? then return nil end
      return @stmt_list[0]
    end

    sig { returns(T.nilable(IL::Statement)) }
    def last_stmt
      if @stmt_list.empty? then return nil end
      return @stmt_list[-1]
    end

    sig { returns(String) }
    def to_s
      str = "[BLOCK (len=#{length})]\n"
      each_stmt { |s|
        str += s.to_s + "\n"
      }
      return str
    end
  end

  sig { params(program: IL::Program).returns(T::Array[Block]) }
  def self.create_blocks(program)
    blocks = []
    stmt_list = []

    program.each_stmt { |s|
      # mark beginning of a block
      if s.is_a?(IL::Label) and not stmt_list.empty?
        blocks.push(Block.new(blocks.length, stmt_list))
        stmt_list = []
      end

      stmt_list.push(s)

      # mark end of a block
      if s.is_a?(IL::Jump) # block will never be empty due to above push
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
