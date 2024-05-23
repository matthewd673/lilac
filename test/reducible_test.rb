# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/il"
require_relative "../lib/analysis/bb"
require_relative "../lib/analysis/cfg"
require_relative "../lib/analysis/reducible"

class ReducibleTest < Minitest::Test
  extend T::Sig

  include Lilac::IL
  include Lilac::Analysis

  sig { void }
  def test_reducible_one
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Type::I32, 0), "L2"),
        Label.new("L1"),
        Label.new("L2"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks:)

    assert Reducible.new(cfg).run
  end

  sig { void }
  def test_irreducible_one
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Type::I32, 0), "L2"),
        Label.new("L1"),
        Jump.new("L2"),
        Label.new("L2"),
        Jump.new("L1"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks:)

    refute Reducible.new(cfg).run
  end

  sig { void }
  def test_irreducible_two
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Type::I32, 0), "L2"),
        Label.new("L1"),
        JumpNotZero.new(Constant.new(Type::I32, 0), "L2"),
        Label.new("L2"),
        JumpNotZero.new(Constant.new(Type::I32, 0), "L1"),
        Label.new("L3"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks:)

    refute Reducible.new(cfg).run
  end
end
