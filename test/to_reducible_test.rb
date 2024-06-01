# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/il"
require_relative "../lib/analysis/bb"
require_relative "../lib/analysis/cfg"
require_relative "../lib/analysis/reducible"
require_relative "../lib/transformations/to_reducible"
require_relative "../lib/debugging/graph_visualizer"

class ToReducibleTest < Minitest::Test
  extend T::Sig

  include Lilac::IL
  include Lilac::Analysis
  include Lilac::Transformations

  sig { void }
  def test_already_reducible
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Types::I32.new, 0), "L2"),
        Label.new("L1"),
        Label.new("L2"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks:)

    assert Reducible.new(cfg).run

    to_reducible = ToReducible.new(cfg)
    to_reducible.run!

    assert Reducible.new(cfg).run
  end

  sig { void }
  def test_irreducible_one
    program = Program.new(stmt_list:
      [
        JumpNotZero.new(Constant.new(Types::I32.new, 0), "L2"),
        Label.new("L1"),
        JumpNotZero.new(Constant.new(Types::I32.new, 0), "L2"),
        Label.new("L2"),
        JumpNotZero.new(Constant.new(Types::I32.new, 0), "L1"),
        Label.new("L3"),
      ])

    blocks = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(blocks:)

    refute Reducible.new(cfg).run

    to_reducible = ToReducible.new(cfg)
    to_reducible.run!

    assert Reducible.new(cfg).run
  end
end
