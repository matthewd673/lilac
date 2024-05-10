# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require_relative "pass"

module Lilac
  # A Runner runs Passes on a Program.
  class Runner
    extend T::Sig
    extend T::Generic

    P = type_member { { upper: Pass } }

    sig { returns(IL::Program) }
    # The Program that the Runner is operating on.
    # @return [IL::Program] The Program.
    attr_reader :program

    sig { params(program: IL::Program).void }
    # Construct a new Runner.
    def initialize(program)
      @program = program
    end

    sig { params(pass: P).void }
    # Run a Pass on the Program.
    # @param [Pass] pass The Pass to run.
    def run_pass(pass)
      raise("run_pass is unimplemented")
    end

    sig { params(pass_list: T::Array[P]).void }
    # Run a list of passes on the Program.
    # @param [T::Array[Pass]] pass_list The list of Passes to run.
    def run_passes(pass_list)
      pass_list.each do |p|
        run_pass(p)
      end
    end
  end
end
