# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/analysis/bb"

class ToBBTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Analysis

  sig { void }
  def test_programs_to_bb
    # NOTE: testing procedure adapted from ToCFGTest
    PROGRAMS.each do |p|
      program_filename = "test/programs/cfg/#{p}.txt"
      expected_filename = "test/programs/cfg/expected/#{p}.yaml"

      stmt_list = load_program_stmt_list(program_filename)
      blocks = BB.from_stmt_list(stmt_list)
      expected = load_expected_cfg(expected_filename)

      validate_entries_and_exits(stmt_list, blocks)
      validate_number_of_blocks(blocks, expected)
    end
  end

  private

  sig { params(stmt_list: T::Array[IL::Statement], blocks: T::Array[BB]).void }
  # Validate that every Label and Jump in the Statement list appears in exactly
  # one BB's entry/exit attribute.
  def validate_entries_and_exits(stmt_list, blocks)
    entry_cts = {}
    exit_cts = {}

    stmt_list.each do |s|
      if s.is_a?(IL::Label)
        entry_cts[s] = 0
      elsif s.is_a?(IL::Jump)
        exit_cts[s] = 0
      end
    end

    blocks.each do |b|
      if b.entry
        assert entry_cts.key?(b.entry)
        entry_cts[b.entry] += 1
      end

      if b.exit
        assert exit_cts.key?(b.exit)
        exit_cts[b.exit] += 1
      end
    end

    entry_cts.each_value { |v| assert_equal(v, 1) }
    exit_cts.each_value { |v| assert_equal(v, 1) }
  end

  sig { params(blocks: T::Array[BB], expected: CFG).void }
  def validate_number_of_blocks(blocks, expected)
    # entry and exit nodes don't count
    assert_equal(blocks.length, expected.nodes_length - 2)
  end

  sig { params(il_file: String).returns(T::Array[IL::Statement]) }
  # NOTE: adapted from ToCFGTest::load_program_cfg
  def load_program_stmt_list(il_file)
    Frontend::Parser.parse_file(il_file).stmt_list
  end

  sig { params(yaml_file: String).returns(CFG) }
  # NOTE: copied from ToCFGTest::load_expected_cfg
  def load_expected_cfg(yaml_file)
    # load expected cfg
    expected_fp = File.open(yaml_file)
    expected = CFGDeserializer.new(expected_fp.read).deserialize
    expected_fp.close

    expected
  end

  # NOTE: same programs as for ToCFGTest
  PROGRAMS = T.let(%w[one_block branch loop].freeze,
                   T::Array[String])
  private_constant :PROGRAMS
end
