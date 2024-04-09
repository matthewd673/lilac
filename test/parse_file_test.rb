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
    expected = Program.new
    expected.stmt_list.push(Definition.new(Type::I32,
                                           ID.new("a"),
                                           Constant.new(Type::I32, 5)))

    program = Frontend::Parser::parse_file("test/il_programs/definition.txt")

    assert program.eql?(expected)
  end

  private

  sig { params(a: Program, b: Program).returns(T::Boolean) }
  def program_match?(a, b)
    true # TODO
  end
end
