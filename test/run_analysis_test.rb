# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/il"
require_relative "../lib/analysis/cfg"

require_relative "../lib/analysis/analysis"
require_relative "../lib/analysis/live_vars"
require_relative "../lib/analysis/reaching_defs"

class RunAnalysisTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Analysis

  sig { void }
  def test_analyses_run_without_exception
    files = Dir["test/programs/fancy/*"] + Dir["test/programs/frontend/*"]

    files.each do |f|
      program = Frontend::Parser.parse_file(f)

      # because analyses are never destructive we don't need to worry
      # about recreating the CFGs every time
      cfg_program = IL::CFGProgram.from_program(program)

      DFA_ANALYSES.each do |a|
        # run on every cfg in the program
        cfg_program.each_func do |f|
          a.new(f.cfg).run

          assert(true) # TODO: is there a better way to "refute_raises"?
        end
      end
    end
  end

  private

  DFA_ANALYSES = T.let([
    Lilac::Analysis::LiveVars,
    Lilac::Analysis::ReachingDefs,
  ], T::Array[DFA])
  private_constant :DFA_ANALYSES
end

