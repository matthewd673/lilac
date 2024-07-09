# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "helpers/cfg_serializer"
require_relative "helpers/cfg_equality"
require_relative "../lib/frontend/parser"
require_relative "../lib/analysis/bb"
require_relative "../lib/analysis/cfg"

class ToCFGTest < Minitest::Test
  extend T::Sig

  include Lilac
  include Lilac::Analysis

  sig { void }
  def test_programs_to_cfg
    PROGRAMS.each do |p|
      program_filename = "test/programs/cfg/#{p}.txt"
      expected_filename = "test/programs/cfg/expected/#{p}.yaml"

      cfg = load_program_cfg(program_filename)
      expected = load_expected_cfg(expected_filename)

      validate_entry_exit(cfg)
      validate_path_to_exit(cfg)
      validate_edges(cfg)

      CFGEquality.assert_cfg_equal(cfg, expected)
    end
  end

  private

  sig { params(cfg: CFG).void }
  # Validate that the CFG has a valid ENTRY and EXIT node.
  def validate_entry_exit(cfg)
    entry_ct = 0
    exit_ct = 0

    cfg.each_node do |n|
      if n.id == CFG::ENTRY
        entry_ct += 1
        assert_equal(cfg.entry, n)
      elsif n.id == CFG::EXIT
        exit_ct += 1
        assert_equal(cfg.exit, n)
      end
    end

    assert entry_ct == 1 && exit_ct == 1
  end

  sig { params(cfg: CFG).void }
  # Validate that there exists a path from ENTRY to EXIT in the CFG.
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
  # Validate that the CFG has valid edges.
  def validate_edges(cfg)
    cfg.each_node do |n|
      assert n == cfg.entry || cfg.predecessors_length(n) > 0
      assert n == cfg.exit || cfg.successors_length(n) > 0
    end
  end

  sig { params(il_file: String).returns(CFG) }
  def load_program_cfg(il_file)
    program = Frontend::Parser.parse_file(il_file)
    main = program.get_func("main")

    # compute cfg for program
    blocks = BB.from_stmt_list(T.must(main).stmt_list)
    CFG.new(blocks:)
  end

  sig { params(yaml_file: String).returns(CFG) }
  def load_expected_cfg(yaml_file)
    # load expected cfg
    expected_fp = File.open(yaml_file)
    expected = CFGDeserializer.new(expected_fp.read).deserialize
    expected_fp.close

    expected
  end

  PROGRAMS = T.let(%w[one_block branch loop].freeze,
                   T::Array[String])
  private_constant :PROGRAMS
end
