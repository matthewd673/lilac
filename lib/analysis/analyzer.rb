# typed: strict
require "sorbet-runtime"
require_relative "analysis"

module Analyzer
  extend T::Sig

  sig { params(analysis: Analysis).void }
  def self.run_analysis(analysis)
    # TODO: temp
    Kernel::puts("[#{analysis.id}] #{analysis.full_name}")
  end
end
