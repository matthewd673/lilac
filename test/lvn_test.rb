# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "helpers/bb_equality"
require_relative "../lib/frontend/parser"
require_relative "../lib/analysis/bb"
require_relative "../lib/optimization/lvn"

class LVNTest < Minitest::Test
  extend T::Sig

  include Lilac

  sig { void }
  def test_lvn_programs
    PROGRAMS.each do |p|
      program_filename = "test/programs/lvn/#{p}.txt"
      expected_filename = "test/programs/lvn/#{p}_expected.txt"

      program_bb = load_program_bb(program_filename)
      program_bb.each do |b|
        lvn = Optimization::LVN.new(b)
        lvn.run!
      end

      expected_bb = load_program_bb(expected_filename)

      BBEquality.assert_bb_equal(program_bb, expected_bb)
    end
  end

  private

  sig { params(il_file: String).returns(T::Array[Analysis::BB]) }
  def load_program_bb(il_file)
    program = Frontend::Parser.parse_file(il_file)
    Analysis::BB.from_stmt_list(program.stmt_list)
  end

  PROGRAMS = T.let(%w[simple constant_folding non_constant_id].freeze,
                   T::Array[String])
  private_constant :PROGRAMS
end
