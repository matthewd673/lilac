# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/frontend/parser"
require_relative "../lib/il"
require_relative "../lib/analysis/cfg"
require_relative "../lib/optimization/optimizations"
require_relative "../lib/optimization/optimization_runner"

class RunOptimizationTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Optimization

  sig { void }
  def test_optimizations_run_without_exception
    files = Dir["test/programs/fancy/*"] + Dir["test/programs/frontend/*"]

    files.each do |f|
      program = Frontend::Parser.parse_file(f)

      OPTIMIZATIONS.each do |o|
        # set up cfg program from scratch each time so that each optimization
        # is running independently of each other
        cfg_program = IL::CFGProgram.from_program(program)
        runner = Optimization::OptimizationRunner.new(cfg_program)
        runner.run_pass(o)

        assert(true) # TODO: is there a better way to "refute_raises"?
      end
    end
  end
end
