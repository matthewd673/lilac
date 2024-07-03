# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require "yaml"
require_relative "helpers/cfg_facts_equality"
require_relative "../lib/frontend/parser"
require_relative "../lib/analysis/bb"
require_relative "../lib/analysis/cfg"
require_relative "../lib/analysis/live_vars"

class LiveVarsTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Analysis

  sig { void }
  def test_live_vars_programs
    PROGRAMS.each do |p|
      program_filename = "test/programs/live_vars/#{p}.txt"
      expected_filename = "test/programs/live_vars/#{p}_expected.yml"

      program_cfg = load_program_cfg(program_filename)
      live_vars = LiveVars.new(program_cfg)
      program_facts = live_vars.run

      expected = load_cfgfacts_yml(expected_filename)

      CFGFactsEquality.assert_cfg_facts_equal(program_facts, expected)
    end
  end

  private

  sig { params(il_file: String).returns(CFG) }
  def load_program_cfg(il_file)
    program = Frontend::Parser.parse_file(il_file)
    CFG.new(blocks: BB.from_stmt_list(program.stmt_list))
  end

  sig { params(yml_file: String).returns(T::Array[T::Hash[String, T.untyped]]) }
  def load_cfgfacts_yml(yml_file)
    fp = File.open(yml_file)
    yml_contents = fp.read
    fp.close

    YAML.load(yml_contents)
  end

  PROGRAMS = T.let(%w[one_block].freeze, T::Array[String])
  private_constant :PROGRAMS
end
