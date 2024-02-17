# typed: true
require "sorbet-runtime"
require_relative "../il"

module BB
  extend T::Sig

  class Block
    extend T::Sig

    sig { void }
    def initialize
      @stmt_list = []
    end

    sig { params(stmt: IL::Statement).void }
    def push_stmt(stmt)
      @stmt_list.push(stmt)
    end

    def length
      @stmt_list.length
    end

    def each_stmt(&block)
      @stmt_list.each(&block)
    end

    def each_stmt_with_index(&block)
      @stmt_list.each_with_index(&block)
    end

    sig { returns(String) }
    def to_s
      str = "---BLOCK (len=#{length})---\n"
      each_stmt { |s|
        str += s.to_s + "\n"
      }
      return str
    end
  end

  sig { params(program: IL::Program).returns(T::Array[Block]) }
  def self.create_blocks(program)
    blocks = [Block.new]

    program.each_stmt { |s|
      # mark beginning of a block
      if s.is_a?(IL::Label)
        blocks.push(Block.new)
      end

      blocks[-1].push_stmt(s)

      # mark end of a block
      if s.is_a?(IL::Jump)
        blocks.push(Block.new)
      end
    }

    return blocks
  end
end
