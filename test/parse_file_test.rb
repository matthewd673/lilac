# typed: strict
require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/il"
require_relative "../lib/frontend/parser"

class ParseFileTest < Minitest::Test
  extend T::Sig

  include IL

  sig { void }
  def test_parse_definition
    expected = Program.new(stmt_list: [
      Definition.new(Type::I32, ID.new("a"), Constant.new(Type::I32, 5)),
    ])
    program = Frontend::Parser::parse_file("test/il_programs/definition.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_types
    expected = Program.new(stmt_list: [
      Definition.new(Type::U8, ID.new("a"), Constant.new(Type::U8, 8)),
      Definition.new(Type::I16, ID.new("b"), Constant.new(Type::I16, -3)),
      Definition.new(Type::I32, ID.new("c"), Constant.new(Type::I32, 5)),
      Definition.new(Type::I64, ID.new("d"), Constant.new(Type::I64, 9999)),
      Definition.new(Type::F32, ID.new("e"), Constant.new(Type::F32, 3.14)),
      Definition.new(Type::F64, ID.new("f"), Constant.new(Type::F64, -1.0)),
    ])
    program = Frontend::Parser::parse_file("test/il_programs/types.txt")

    assert program.eql?(expected)
  end
end
