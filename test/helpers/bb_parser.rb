# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "../../lib/il"
require_relative "../../lib/analysis/bb"
require_relative "../../lib/frontend/parser"

class BBParser
  extend T::Sig

  include Lilac

  sig { params(string: String).void }
  def initialize(string)
    @string = string
  end

  sig { returns(T::Array[Analysis::BB]) }
  def parse
    lines = @string.split("\n")
    blocks = []

    lines.each do |l|
      m = l.match(BLOCK_HEADER)
      # begin a new block
      if m
        id = T.must(m[1])

        # add entry if specified
        entry_str = m[3]
        if entry_str
          entry_parser = Frontend::Parser.new(entry_str)
          block_entry = T.cast(
            T.must(entry_parser.parse_statement[0]),
            IL::Label)
        end

        # add exit if specified
        exit_str = m[5]
        if exit_str
          exit_parser = Frontend::Parser.new(exit_str)
          block_exit = T.cast(
            T.must(exit_parser.parse_statement[0]),
            IL::Jump)
        end

        # mark as true branch if designated
        true_branch = m[6] ? true : false

        blocks.push(Analysis::BB.new(id,
                                     entry: block_entry,
                                     exit: block_exit,
                                     true_branch:))
        next
      end

      # add statement to the old block
      il_parser = Frontend::Parser.new(l)
      stmt = il_parser.parse_statement[0]
      if stmt
        if blocks.last == nil
          raise "Parsed a statement but no blocks have been defined yet"
        end

        last_block = T.unsafe(blocks.last)
        last_block.stmt_list.push(stmt)
      end
    end

    blocks
  end

  private

  BLOCK_HEADER = T.let(
    /\[(BB[a-zA-Z0-9_]+)( ENTRY=\[([^\]]*)\])?( EXIT=\[([^\]]*)\])?( TRUE_BRANCH)?\]/,
    Regexp
  )
  private_constant :BLOCK_HEADER
end
