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
  def test_tee_valid_one
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
  def test_tee_valid_two
    original = [
      LocalGet.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalSet.new("0"),
      LocalGet.new("0"),
      EqualZero.new(Type::I32),
    ]

    expected = [
      LocalGet.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalTee.new("0"),
      EqualZero.new(Type::I32),
    ]

    tee = CodeGen::Targets::Wasm::Optimization::Tee.new(original)
    tee.run

    assert original.eql?(expected)
  end

  sig { void }
  def test_tee_valid_three
    original = [
      Local.new(Type::I32, "a"),
      Local.new(Type::I32, "b"),
      Local.new(Type::I32, "0"),
      Local.new(Type::I32, "1"),
      Local.new(Type::I32, "2"),
      Local.new(Type::I32, "c"),
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      Const.new(Type::I32, 1),
      LocalSet.new("b"),
      Block.new("block_0"),
      LocalGet.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalSet.new("0"),
      LocalGet.new("0"),
      EqualZero.new(Type::I32),
      BranchIf.new("block_0"),
      Loop.new("loop_0"),
      LocalGet.new("b"),
      Const.new(Type::I32, 2),
      Multiply.new(Type::I32),
      LocalSet.new("1"),
      LocalGet.new("1"),
      LocalSet.new("b"),
      LocalGet.new("a"),
      Const.new(Type::I32, 1),
      Subtract.new(Type::I32),
      LocalSet.new("2"),
      LocalGet.new("2"),
      LocalSet.new("a"),
      LocalGet.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalSet.new("0"),
      LocalGet.new("0"),
      EqualZero.new(Type::I32),
      BranchIf.new("block_0"),
      Branch.new("loop_0"),
      End.new,
      End.new,
      LocalGet.new("b"),
      LocalSet.new("c"),
      Return.new,
    ]

    expected = [
      Local.new(Type::I32, "a"),
      Local.new(Type::I32, "b"),
      Local.new(Type::I32, "0"),
      Local.new(Type::I32, "1"),
      Local.new(Type::I32, "2"),
      Local.new(Type::I32, "c"),
      Const.new(Type::I32, 5),
      LocalSet.new("a"),
      Const.new(Type::I32, 1),
      LocalSet.new("b"),
      Block.new("block_0"),
      LocalGet.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalTee.new("0"),
      EqualZero.new(Type::I32),
      BranchIf.new("block_0"),
      Loop.new("loop_0"),
      LocalGet.new("b"),
      Const.new(Type::I32, 2),
      Multiply.new(Type::I32),
      LocalTee.new("1"),
      LocalSet.new("b"),
      LocalGet.new("a"),
      Const.new(Type::I32, 1),
      Subtract.new(Type::I32),
      LocalTee.new("2"),
      LocalTee.new("a"),
      Const.new(Type::I32, 0),
      GreaterThanSigned.new(Type::I32),
      LocalTee.new("0"),
      EqualZero.new(Type::I32),
      BranchIf.new("block_0"),
      Branch.new("loop_0"),
      End.new,
      End.new,
      LocalGet.new("b"),
      LocalSet.new("c"),
      Return.new,
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
