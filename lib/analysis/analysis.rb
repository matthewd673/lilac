# typed: strict
require "sorbet-runtime"
require_relative "../il"

class Analysis
  extend T::Sig

  sig { returns(String) }
  attr_reader :id
  sig { returns(String) }
  attr_reader :full_name
  sig { returns(Integer) }
  attr_reader :level

  sig { void }
  def initialize
    # NOTE: these should always be overwritten by subclasses
    @id = T.let("analysis", String)
    @full_name = T.let("Analysis stub", String)
    @level = T.let(1, Integer)
  end
end
