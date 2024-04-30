# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require_relative "optimization"
require_relative "../../../../pass"
require_relative "../instructions/instructions"

module CodeGen
  module Targets
  module Wasm
  module Optimization
  class Tee < Pass
  extend T::Sig

  include CodeGen::Targets::Wasm

  sig { override.returns(String) }
  def id
    "tee"
  end

  sig { override.returns(String) }
  def description
    "Combine consecutive get and set instructions into a tee instruction"
  end

  sig { params(instructions: T::Array[Instructions::WasmInstruction]).void }
  def initialize(instructions)
    @instructions = instructions
  end

  sig { void }
  def run
    last = T.let(nil, T.nilable(Instructions::WasmInstruction))
    i = 0
    while i < @instructions.length
      # NOTE: Sorbet doesn't require this let but it helped catch a lot of type
      # errors so I'm leaving it in
      inst = T.let(@instructions[i], T.nilable(Instructions::WasmInstruction))

      unless inst # should never happen
        break
      end

      # skip first instruction
      unless last
        last = inst
        i += 1
        next
      end

      # if last was set and this is get, make tee...
      if last.is_a?(Instructions::LocalSet) and
          inst.is_a?(Instructions::LocalGet) and
          last.variable == inst.variable
        tee = Instructions::LocalTee.new(inst.variable)

        @instructions.insert(i, tee)
        @instructions.delete(last)
        @instructions.delete(inst)

        i -= 2

        last = tee
      else
        last = inst
      end

      i += 1
    end
  end
  end
  end
  end
  end
end
