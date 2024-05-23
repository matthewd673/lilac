# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "helpers/cfg_serializer"
require_relative "../lib/frontend/parser"
require_relative "../lib/analysis/bb"
require_relative "../lib/analysis/cfg"

class ToCFGTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Analysis

  sig { void }
  def test_cfg_programs
    PROGRAMS.each do |p|
      program = Frontend::Parser.parse_file(p)

      blocks = BB.from_stmt_list(program.stmt_list)
      cfg = CFG.new(blocks:)

      validate_entry_exit(cfg)
      validate_path_to_exit(cfg)
      validate_edges(cfg)
    end
  end

  private

  sig { params(cfg: CFG).void }
  def validate_entry_exit(cfg)
    entry_ct = 0
    exit_ct = 0

    cfg.each_node do |n|
      if n.id == CFG::ENTRY
        entry_ct += 1
        assert cfg.entry == n # NOTE: want shallow eql here
      elsif n.id == CFG::EXIT
        exit_ct += 1
        assert cfg.exit == n # NOTE: want shallow eql here
      end
    end

    assert entry_ct == 1 && exit_ct == 1
  end

  sig { params(cfg: CFG).void }
  def validate_path_to_exit(cfg)
    seen_exit = T.let(false, T::Boolean)

    cfg.postorder_traversal(cfg.entry) do |n|
      if n == cfg.exit
        seen_exit = true
      end
    end

    assert seen_exit
  end

  sig { params(cfg: CFG).void }
  def validate_edges(cfg)
    cfg.each_node do |n|
      assert n == cfg.entry || cfg.predecessors_length(n) > 0
      assert n == cfg.exit || cfg.successors_length(n) > 0
    end
  end

  PROGRAMS = T.let([
    "test/programs/cfg/one_block.txt",
    "test/programs/cfg/branch.txt",
    "test/programs/cfg/loop.txt",
  ].freeze, T::Array[String])
  private_constant :PROGRAMS
end
