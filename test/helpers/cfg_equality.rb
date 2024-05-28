# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest"
require_relative "../../lib/analysis/cfg"

module CFGEquality
  extend T::Sig
  extend Minitest::Assertions

  include Lilac::Analysis

  # support minitest assertions
  class << self
    extend T::Sig

    sig { returns(Integer) }
    attr_accessor :assertions

    sig { void }
    # This initialize is never called, but it makes Sorbet think that
    # @assertions is defined.
    def initialize
      @assertions = T.let(0, Integer)
    end
  end
  # This is what actually initializes @assertions to 0
  self.assertions = 0

  sig { params(actual: CFG, expected: CFG).void }
  def self.assert_cfg_equal(actual, expected)
    # clone so IDs can be overwritten
    actual = actual.clone
    expected = expected .clone

    # must have same number of nodes and edges
    assert_equal(actual.nodes_length,
                 expected.nodes_length,
                 message do
                   "CFG node length differs: saw #{actual.nodes_length}, "\
                   "expected #{expected.nodes_length}"
                 end)

    assert_equal(actual.edges_length,
                 expected.edges_length,
                 message do
                   "CFG edges length differs: saw #{actual.edges_length}, "\
                   "expected #{expected.edges_length}"
                 end)

    # TODO: more in-depth equality check

    # get preorder- and postorder-numbering of each node for each tree
    # a_pre = a.preorder_numbering(a.entry)
    # b_pre = b.preorder_numbering(b.entry)

    # a_post = a.postorder_numbering(a.entry)
    # b_post = b.postorder_numbering(b.entry)

    # # combine pre and post numbers into new IDs
    # a.each_node { |n| n.id = "#{a_pre[n]},#{a_post[n]}" }
    # b.each_node { |n| n.id = "#{b_pre[n]},#{b_post[n]}" }

    # a.each_node { |n| puts "a => #{n.id}" }
    # b.each_node { |n| puts "b => #{n.id}" }
  end
end
