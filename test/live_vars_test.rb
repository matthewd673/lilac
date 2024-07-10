# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require "yaml"
require_relative "helpers/bb_parser"
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

      blocks = load_blocks(program_filename)
      cfg = CFG.new(blocks:)

      live_vars = LiveVars.new(cfg)
      program_facts = live_vars.run

      expected = load_cfgfacts_yml(expected_filename)

      CFGFactsEquality.assert_cfg_facts_equal(program_facts, expected)
    end
  end

  private

  sig { params(ilbb_file: String).returns(T::Array[BB]) }
  def load_blocks(ilbb_file)
    parser = BBParser.new(File.open(ilbb_file, "r").read)
    parser.parse
  end

  sig { params(yml_file: String).returns(T::Array[T::Hash[String, T.untyped]]) }
  def load_cfgfacts_yml(yml_file)
    fp = File.open(yml_file)
    yml_contents = fp.read
    fp.close

    YAML.load(yml_contents)
  end

  PROGRAMS = T.let(%w[one_block book92].freeze, T::Array[String])
  private_constant :PROGRAMS
end
