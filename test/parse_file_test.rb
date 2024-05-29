# typed: strict
# frozen_string_literal: true

require "sorbet-runtime"
require "minitest/autorun"
require_relative "../lib/il"
require_relative "../lib/frontend/parser"

class ParseFileTest < Minitest::Test
  extend T::Sig

  include Lilac::IL

  sig { void }
  def test_parse_definition
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::I32.new, ID.new("a"),
                       Constant.new(Types::I32.new, 5)),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/definition.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_types
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::U8.new, ID.new("a"),
                       Constant.new(Types::U8.new, 8)),
        Definition.new(Types::U16.new, ID.new("b"),
                       Constant.new(Types::U16.new, 9)),
        Definition.new(Types::U32.new, ID.new("c"),
                       Constant.new(Types::U32.new, 10)),
        Definition.new(Types::U64.new, ID.new("d"),
                       Constant.new(Types::U64.new, 11)),
        Definition.new(Types::I8.new, ID.new("e"),
                       Constant.new(Types::I8.new, -2)),
        Definition.new(Types::I16.new, ID.new("f"),
                       Constant.new(Types::I16.new, -3)),
        Definition.new(Types::I32.new, ID.new("g"),
                       Constant.new(Types::I32.new, 5)),
        Definition.new(Types::I64.new, ID.new("h"),
                       Constant.new(Types::I64.new, 9999)),
        Definition.new(Types::F32.new, ID.new("i"),
                       Constant.new(Types::F32.new, 3.14)),
        Definition.new(Types::F64.new, ID.new("j"),
                       Constant.new(Types::F64.new, -1.0)),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/types.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_label_and_jmp
    expected = Program.new(
      stmt_list: [
        Label.new("L0"),
        Definition.new(Types::I32.new, ID.new("a"),
                       Constant.new(Types::I32.new, 3)),
        Jump.new("L0"),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/label_and_jmp.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_jz_jnz
    expected = Program.new(
      stmt_list: [
        Label.new("L0"),
        Definition.new(Types::I32.new, ID.new("a"),
                       Constant.new(Types::I32.new, 5)),
        JumpNotZero.new(ID.new("a"), "L0"),
        JumpZero.new(Constant.new(Types::U8.new, 1), "L0"),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/jz_jnz.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_binop
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::I32.new, ID.new("a"),
                       BinaryOp.new(
                         BinaryOp::Operator::ADD,
                         Constant.new(Types::I32.new, 12),
                         Constant.new(Types::I32.new, 6)
                       )),
        Definition.new(Types::I32.new, ID.new("a"),
                       BinaryOp.new(
                         BinaryOp::Operator::SUB,
                         ID.new("a"),
                         Constant.new(Types::I32.new, 0)
                       )),
        Definition.new(Types::I32.new, ID.new("a"),
                       BinaryOp.new(
                         BinaryOp::Operator::MUL,
                         ID.new("a"),
                         Constant.new(Types::I32.new, -2)
                       )),
        Definition.new(Types::I32.new, ID.new("a"),
                       BinaryOp.new(
                         BinaryOp::Operator::DIV,
                         ID.new("a"),
                         Constant.new(Types::I32.new, -2)
                       )),
        Definition.new(Types::U8.new, ID.new("b"),
                       BinaryOp.new(
                         BinaryOp::Operator::EQ,
                         Constant.new(Types::U8.new, 0),
                         Constant.new(Types::U8.new, 0)
                       )),
        Definition.new(Types::U8.new, ID.new("c"),
                       BinaryOp.new(
                         BinaryOp::Operator::NEQ,
                         Constant.new(Types::U8.new, 1),
                         Constant.new(Types::U8.new, 0)
                       )),
        Definition.new(Types::U8.new, ID.new("d"),
                       BinaryOp.new(
                         BinaryOp::Operator::LT,
                         Constant.new(Types::U8.new, 2),
                         Constant.new(Types::U8.new, 4)
                       )),
        Definition.new(Types::U8.new, ID.new("e"),
                       BinaryOp.new(
                         BinaryOp::Operator::GT,
                         Constant.new(Types::U8.new, 3),
                         Constant.new(Types::U8.new, 1)
                       )),
        Definition.new(Types::U8.new, ID.new("f"),
                       BinaryOp.new(
                         BinaryOp::Operator::LEQ,
                         Constant.new(Types::U8.new, 1),
                         Constant.new(Types::U8.new, 1)
                       )),
        Definition.new(Types::U8.new, ID.new("g"),
                       BinaryOp.new(
                         BinaryOp::Operator::GEQ,
                         Constant.new(Types::U8.new, 0),
                         Constant.new(Types::U8.new, 1)
                       )),
        Definition.new(Types::U8.new, ID.new("h"),
                       BinaryOp.new(
                         BinaryOp::Operator::BOOL_OR,
                         Constant.new(Types::U8.new, 1),
                         Constant.new(Types::U8.new, 0)
                       )),
        Definition.new(Types::U8.new, ID.new("i"),
                       BinaryOp.new(
                         BinaryOp::Operator::BOOL_AND,
                         Constant.new(Types::U8.new, 0),
                         Constant.new(Types::U8.new, 1)
                       )),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/binop.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_unop
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::I16.new, ID.new("a"),
                       UnaryOp.new(
                         UnaryOp::Operator::NEG,
                         Constant.new(Types::I16.new, 2)
                       )),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/unop.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_func
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::I32.new, ID.new("ans"),
                       Call.new(
                         "multiply",
                         [
                           Constant.new(Types::I32.new, 3),
                           Constant.new(Types::I32.new, 5),
                         ]
                       )),
      ]
    )
    expected.add_func(
      FuncDef.new(
        "multiply",
        [
          FuncParam.new(Types::I32.new, ID.new("a")),
          FuncParam.new(Types::I32.new, ID.new("b")),
        ],
        Types::I32.new,
        [
          Definition.new(Types::I32.new,
                         Register.new(0),
                         BinaryOp.new(
                           BinaryOp::Operator::MUL,
                           ID.new("a"),
                           ID.new("b")
                         )),
          Return.new(Register.new(0)),
        ]
      )
    )

    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/func.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_phi
    expected = Program.new(
      stmt_list: [
        Definition.new(Types::I32.new, ID.new("a"),
                       Constant.new(Types::I32.new, 1)),
        Definition.new(Types::I32.new, ID.new("b"),
                       Constant.new(Types::I32.new, 2)),
        Definition.new(Types::I32.new, Register.new(0),
                       BinaryOp.new(
                         BinaryOp::Operator::EQ,
                         ID.new("a"),
                         Constant.new(Types::I32.new, 1)
                       )),
        JumpZero.new(Register.new(0), "L0"),
        Definition.new(Types::I32.new, Register.new(1),
                       BinaryOp.new(
                         BinaryOp::Operator::MUL,
                         ID.new("b"),
                         Constant.new(Types::I32.new, 2)
                       )),
        Definition.new(Types::I32.new, ID.new("b"), Register.new(0)),
        Jump.new("L1"),
        Label.new("L0"),
        Definition.new(Types::I32.new, Register.new(2),
                       BinaryOp.new(
                         BinaryOp::Operator::ADD,
                         ID.new("b"),
                         Constant.new(Types::I32.new, 1)
                       )),
        Definition.new(Types::I32.new, ID.new("b"), Register.new(0)),
        Label.new("L1"),
        Definition.new(Types::I32.new, ID.new("b"),
                       Phi.new([ID.new("b"), ID.new("b")])),
        Definition.new(Types::I32.new, ID.new("c"), ID.new("b")),
      ]
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/phi.txt"
    )

    assert program.eql?(expected)
  end

  sig { void }
  def test_parse_extern
    expected = Program.new(stmt_list: [
                             VoidCall.new(Call.new("main", [])),
                           ])
    expected.add_func(
      FuncDef.new(
        "main", [], Types::Void.new,
        [
          Definition.new(Types::I32.new, Register.new(1),
                         Call.new(
                           "divide",
                           [
                             Constant.new(Types::F64.new, 6.0),
                             Constant.new(Types::F64.new, 3.3),
                           ]
                         )),
          Definition.new(Types::F64.new, ID.new("ans"), Register.new(1)),
          VoidCall.new(ExternCall.new("console", "log", [ID.new("ans")])),
          Return.new(Constant.new(Types::Void.new, nil)),
        ]
      )
    )
    expected.add_func(
      FuncDef.new(
        "divide",
        [FuncParam.new(Types::F64.new, ID.new("a")),
         FuncParam.new(Types::F64.new, ID.new("b"))],
        Types::F64.new,
        [
          Definition.new(Types::F64.new, Register.new(0),
                         BinaryOp.new(
                           BinaryOp::Operator::DIV,
                           ID.new("a"),
                           ID.new("b")
                         )),
          Return.new(Register.new(0)),
        ]
      )
    )
    expected.add_extern_func(
      ExternFuncDef.new("console", "log", [Types::F64.new], Types::Void.new)
    )
    program = Lilac::Frontend::Parser.parse_file(
      "test/programs/frontend/extern.txt"
    )

    assert program.eql?(expected)
  end
end
