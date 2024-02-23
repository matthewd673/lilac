# typed: strict
require "sorbet-runtime"
require_relative "../il"
require_relative "optimization"
require_relative "condense_labels"

class Runner
  extend T::Sig

  sig { params(program: IL::Program).void }
  def initialize(program)
    @program = program
  end

  sig { params(opt: Optimization).void }
  def run_pass(opt)
    Kernel::puts("Running #{opt.id}")
    opt.run(@program)
  end

  sig { params(opt_list: T::Array[Optimization]).void }
  def run_passes(opt_list)
    for o in opt_list
      run_pass(o)
    end
  end

  sig { params(level: Integer).returns(T::Array[Optimization]) }
  def level_passes(level)
    OPTIMIZATIONS.select { |o| o.level == level }
  end

  protected

  OPTIMIZATIONS = T.let([
    CondenseLabels.new
  ], T::Array[Optimization])
end
