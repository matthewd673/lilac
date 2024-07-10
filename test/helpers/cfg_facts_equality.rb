# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest"
require_relative "../../lib/analysis/cfg_facts"

module CFGFactsEquality
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

  sig do
    params(actual: CFGFacts[T.untyped],
           expected: T::Array[T::Hash[String, T.untyped]])
      .void
  end
  def self.assert_cfg_facts_equal(actual, expected)
    assert_equal(expected.length,
                 actual.cfg.nodes_length,
                 message { "Number of blocks differ in CFGFacts" })

    actual.cfg.each_node do |n|
      # select the block with the same ID from the expected YAML
      facts = T.unsafe(expected.select { |e| e["id"] == n.id }[0])
      refute_equal(
        facts,
        nil,
        message { "Failed to select expected facts for ID #{n.id}" }
      )

      facts.each_key do |k|
        next if k == "id" # id is not a fact set

        # check that facts match up
        expected_fact = T.unsafe(facts[k])
        # NOTE: actual fact symbols should always be lowercase
        actual_fact = actual.get_fact(k.downcase.to_sym, n)

        assert_equal(expected_fact.length,
                     actual_fact.length,
                     message do
                       "Number of items in fact #{k} differ for #{n.id}. "\
                       "Actual #{k} for #{n.id}: #{actual_fact}"
                     end)

        actual_fact.each do |e|
          assert_includes(expected_fact,
                          e.to_s,
                          message do
                            "Item #{e} does not appear in expected set for "\
                            "block #{n.id}"
                          end)
        end
      end
    end
  end
end
