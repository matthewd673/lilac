# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest"
require_relative "../../lib/il"
require_relative "../../lib/analysis/bb"

module BBEquality
  extend T::Sig
  extend Minitest::Assertions

  include Lilac
  include Lilac::Analysis

  # support minitest assertions
  class << self
    extend T::Sig

    sig { returns(Integer) }
    attr_accessor :assertions

    sig { void }
    # This initialize is never called, but it makes Sorbet think that
    # @assertions is defined.
    def initialize
      @assertions = T.let(0, Integer)
    end
  end
  # This is what actually initializes @assertions to 0
  self.assertions = 0

  sig { params(actual: T::Array[BB], expected: T::Array[BB]).void }
  def self.assert_bb_equal(actual, expected)
    assert_equal(
      actual.length,
      expected.length,
      message do
        "Numer of basic blocks differ: "\
        "saw #{actual.length}, expected #{expected.length}"
      end
    )

    actual.each_with_index do |block_actual, i|
      block_expected = T.unsafe(expected[i])

      # assert that there are the same number of statements
      assert_equal(block_actual.stmt_list.length,
                   block_expected.stmt_list.length,
                   message do
                     "Number of statements in block #{i} differs: "\
                     "saw #{block_actual.stmt_list.length}, "\
                     "expected #{block_expected.stmt_list.length}"
                   end)

      # assert that if one block has an entry/exit then they both do
      refute(block_actual.entry && !block_expected.entry,
             message do
               "Entries of block #{i} differ: saw #{block_actual.entry}, "\
               "expected #{block_expected.entry}"
             end)
      refute(block_actual.exit && !block_expected.exit,
             message do
               "Exits of block #{i} differ: saw #{block_actual.exit}, "\
               "expected #{block_expected.exit}"
             end)

      # if they both have entry/exit, make sure they match
      if block_actual.entry
        assert(block_actual.entry.eql?(block_expected.exit),
               message do
                 "Entries of block #{i} differ: saw #{block_actual.entry}, "\
                 "expected #{block_expected.entry}"
               end)
      end

      if block_actual.exit
        assert(block_actual.exit.eql?(block_expected.exit),
               message do
                 "Exits of block #{i} differ: saw #{block_actual.exit}, "\
                 "expected #{block_expected.exit}"
               end)
      end

      # assert that all statements match
      block_actual.stmt_list.each_with_index do |s_a, s_i|
        s_b = T.unsafe(block_expected.stmt_list[s_i])

        assert(s_a.eql?(s_b),
               message do
                 "Statement mismatch at position #{s_i} "\
                 "in block #{i}: saw #{s_a}, expected #{s_b}"
               end)

        # assert that if one is a true_branch, then both are
        assert_equal(block_actual.true_branch,
                     block_expected.true_branch,
                     message do
                       "Saw block true_branch=#{block_actual.true_branch}, "\
                       "expected block true_branch="\
                       "#{block_expected.true_branch}"
                     end)
      end
    end
  end
end
