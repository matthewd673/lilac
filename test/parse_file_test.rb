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
    program = Frontend::Parser::parse_file("test/il_programs/frontend/definition.txt")

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
    program = Frontend::Parser::parse_file("test/il_programs/frontend/types.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_label_and_jmp
    expected = Program.new(stmt_list: [
      Label.new("L0"),
      Definition.new(Type::I32, ID.new("a"), Constant.new(Type::I32, 3)),
      Jump.new("L0"),
    ])
    program = Frontend::Parser::parse_file("test/il_programs/frontend/label_and_jmp.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_jz_jnz
    expected = Program.new(stmt_list: [
      Label.new("L0"),
      Definition.new(Type::I32, ID.new("a"), Constant.new(Type::I32, 5)),
      JumpNotZero.new(ID.new("a"), "L0"),
      JumpZero.new(Constant.new(Type::U8, 1), "L0"),
    ])
    program = Frontend::Parser::parse_file("test/il_programs/frontend/jz_jnz.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_binop
    expected = Program.new(stmt_list: [
      Definition.new(Type::I32, ID.new("a", number: 0), BinaryOp.new(
        BinaryOp::Operator::ADD,
        Constant.new(Type::I32, 12), Constant.new(Type::I32, 6)
      )),
      Definition.new(Type::I32, ID.new("a", number: 1), BinaryOp.new(
        BinaryOp::Operator::SUB,
        ID.new("a", number: 0), Constant.new(Type::I32, 0)
      )),
      Definition.new(Type::I32, ID.new("a", number: 2), BinaryOp.new(
        BinaryOp::Operator::MUL,
        ID.new("a", number: 1), Constant.new(Type::I32, -2)
      )),
      Definition.new(Type::I32, ID.new("a", number: 3), BinaryOp.new(
        BinaryOp::Operator::DIV,
        ID.new("a", number: 2), Constant.new(Type::I32, -2)
      )),

      Definition.new(Type::U8, ID.new("b"), BinaryOp.new(
        BinaryOp::Operator::EQ,
        Constant.new(Type::U8, 0), Constant.new(Type::U8, 0)
      )),
      Definition.new(Type::U8, ID.new("c"), BinaryOp.new(
        BinaryOp::Operator::NEQ,
        Constant.new(Type::U8, 1), Constant.new(Type::U8, 0)
      )),
      Definition.new(Type::U8, ID.new("d"), BinaryOp.new(
        BinaryOp::Operator::LT,
        Constant.new(Type::U8, 2), Constant.new(Type::U8, 4)
      )),
      Definition.new(Type::U8, ID.new("e"), BinaryOp.new(
        BinaryOp::Operator::GT,
        Constant.new(Type::U8, 3), Constant.new(Type::U8, 1)
      )),
      Definition.new(Type::U8, ID.new("f"), BinaryOp.new(
        BinaryOp::Operator::LEQ,
        Constant.new(Type::U8, 1), Constant.new(Type::U8, 1)
      )),
      Definition.new(Type::U8, ID.new("g"), BinaryOp.new(
        BinaryOp::Operator::GEQ,
        Constant.new(Type::U8, 0), Constant.new(Type::U8, 1)
      )),
      Definition.new(Type::U8, ID.new("h"), BinaryOp.new(
        BinaryOp::Operator::OR,
        Constant.new(Type::U8, 1), Constant.new(Type::U8, 0)
      )),
      Definition.new(Type::U8, ID.new("i"), BinaryOp.new(
        BinaryOp::Operator::AND,
        Constant.new(Type::U8, 0), Constant.new(Type::U8, 1)
      )),
    ])
    program = Frontend::Parser::parse_file("test/il_programs/frontend/binop.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_unop
    expected = Program.new(stmt_list: [
      Definition.new(Type::I16, ID.new("a"), UnaryOp.new(
        UnaryOp::Operator::NEG, Constant.new(Type::I16, 2)))
    ])
    program = Frontend::Parser::parse_file("test/il_programs/frontend/unop.txt")

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_func
    expected = Program.new(stmt_list: [
      Definition.new(Type::I32, ID.new("ans"),
                     Call.new("multiply", [Constant.new(Type::I32, 3),
                                           Constant.new(Type::I32, 5)]))
    ])
    expected.add_func(FuncDef.new("multiply",
                                  [
                                    FuncParam.new(Type::I32, ID.new("a")),
                                    FuncParam.new(Type::I32, ID.new("b"))
                                  ],
                                  Type::I32,
                                  [
                                    Definition.new(Type::I32,
                                                   Register.new(0),
                                                   BinaryOp.new(
                                                     BinaryOp::Operator::MUL,
                                                     ID.new("a"),
                                                     ID.new("b"))),
                                    Return.new(Register.new(0)),
                                  ]
                                 ))

    program = Frontend::Parser::parse_file("test/il_programs/frontend/func.txt")

    assert program.eql?(expected)
  end
end