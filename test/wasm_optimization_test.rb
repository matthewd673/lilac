# typed: strict
# frozen_string_literal: true
require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/code_gen/targets/wasm/type"
require_relative "../lib/code_gen/targets/wasm/instructions/instructions"
require_relative "../lib/code_gen/targets/wasm/instructions/instruction_set"
require_relative "../lib/code_gen/targets/wasm/optimization/tee"

class WasmOptimizationTest < Minitest::Test
  extend T::Sig

  include CodeGen::Targets::Wasm
  include CodeGen::Targets::Wasm::Instructions

  sig { void }
  def test_tee_simple
    original = [
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      LocalGet.new("a"),
      Const.new(Type::I32, 2),
      LocalSet.new("b"),
    ]

    expected = [
      Const.new(Type::I32, 5),
      LocalTee.new("a"),
      Const.new(Type::I32, 2),
      LocalSet.new("b"),
    ]

    tee = CodeGen::Targets::Wasm::Optimization::Tee.new(original)
    tee.run

    assert original.eql?(expected)
  end

  sig { void }
  def test_tee_diff_names
    original = [
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      LocalGet.new("b"),
      Const.new(Type::I32, 2),
      LocalSet.new("c"),
    ]

    expected = [
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      LocalGet.new("b"),
      Const.new(Type::I32, 2),
      LocalSet.new("c"),
    ]

    tee = CodeGen::Targets::Wasm::Optimization::Tee.new(original)
    tee.run

    assert original.eql?(expected)
  end

  sig { void }
  def test_tee_not_consecutive
    original = [
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      Const.new(Type::I32, 2),
      LocalGet.new("a"),
      Subtract.new(Type::I32),
    ]

    expected = [
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      Const.new(Type::I32, 2),
      LocalGet.new("a"),
      Subtract.new(Type::I32),
    ]

    tee = CodeGen::Targets::Wasm::Optimization::Tee.new(original)
    tee.run

    assert original.eql?(expected)
  end
end
