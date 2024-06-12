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

    i = 0
    actual.cfg.each_node do |n|
      facts = T.unsafe(expected[i])
      refute_equal(facts, nil)

      expected_id = facts["name"]

      facts.each_key do |k|
        next if k == "id" # id is not a fact set

        # check that facts match up
        expected_fact = T.unsafe(facts[k])
        actual_fact = actual.get_fact(k.to_sym, n)

        assert_equal(expected_fact.length,
                     actual_fact.length,
                     message do
                       "Number of items in fact #{k} differ for #{expected_id}"
                     end)

        actual_fact.each do |e|
          assert_includes(expected_fact,
                          e.to_s,
                          message do
                            "Item #{e} does not appear in expected set for "\
                            "block #{expected_id}"
                          end)
        end

        puts "EXPECTED: #{expected_fact}"
        puts "ACTUAL: #{actual_fact}"
      end

      i += 1
    end
  end
end
