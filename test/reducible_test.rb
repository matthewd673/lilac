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

  include IL
  include Analysis

  sig { void }
  def test_reducible_one
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Type::I32, 0), "L2"),
        Label.new("L1"),
        Label.new("L2"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks)

    reducible = Reducible.new(cfg)
    assert reducible.run
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
    cfg = CFG.new(blocks)

    reducible = Reducible.new(cfg)
    refute reducible.run
  end
end
