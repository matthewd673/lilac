# typed: strict
require "sorbet-runtime"
require_relative "../il"
require_relative "analysis"
require_relative "condense_labels"
require_relative "remove_useless_jumps"
require_relative "precompute_cond_jumps"
require_relative "lvn"

class Runner
  extend T::Sig

  sig { returns(IL::Program) }
  attr_reader :program

  sig { params(program: IL::Program).void }
  def initialize(program)
    @program = program
  end

  sig { params(analysis: Analysis).void }
  def run_pass(analysis)
    Kernel::puts("Running #{analysis.id}")
    analysis.run(@program)
  end

  sig { params(analysis_list: T::Array[Analysis]).void }
  def run_passes(analysis_list)
    for a in analysis_list
      run_pass(a)
    end
  end

  sig { params(level: Integer).returns(T::Array[Analysis]) }
  def level_passes(level)
    ANALYSES.select { |a| a.level == level }
  end

  protected

  ANALYSES = T.let([
    CondenseLabels.new,
    RemoveUselessJumps.new,
    LVN.new,
    PrecomputeCondJumps.new,
  ], T::Array[Analysis])
end
