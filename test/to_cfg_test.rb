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
  def test_one_block
    program = Frontend::Parser.parse_file("test/programs/cfg/one_block.txt")

    bb = BB.from_stmt_list(program.stmt_list)
    cfg = CFG.new(bb)

    validate_entry_exit(cfg)
  end

  private

  sig { params(cfg: CFG).void }
  def validate_entry_exit(cfg)
    entry_ct = 0
    exit_ct = 0

    cfg.each_node do |n|
      if n.id == CFG::ENTRY
        entry_ct += 1
        assert cfg.entry == n
      elsif n.id == CFG::EXIT
        exit_ct += 1
        assert cfg.exit == n
      end
    end

    assert entry_ct == 1 && exit_ct == 1
  end
end
