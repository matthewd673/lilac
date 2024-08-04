using Lilac.IL;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.FrontendTests;

public class ParseFileTests {
  [Fact]
  public void ParseDefinition() {
    Program expected = new();
    FuncDef main = new("main",
                       [],
                       Type.Void,
                       [
                         new Definition(Type.I32, new ID("a"),
                                        new ValueExpr(
                                          new Constant(Type.I32, 5L)
                                        )),
                       ]
                      );
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/definition.lilac");

    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseBinop() {
    Program expected = new();
    FuncDef main = new("main",
                       [],
                       Type.Void,
                       [
                         new Definition(Type.I32, new ID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Add,
                                           new Constant(Type.I32, 12L),
                                           new Constant(Type.I32, 6L)
                                          )
                                        ),
                         new Definition(Type.I32, new ID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Sub,
                                           new ID("a"),
                                           new Constant(Type.I32, 0L)
                                          )
                                        ),
                         new Definition(Type.I32, new ID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Mul,
                                           new ID("a"),
                                           new Constant(Type.I32, -2L)
                                          )
                                        ),
                         new Definition(Type.I32, new ID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Div,
                                           new ID("a"),
                                           new Constant(Type.I32, -2L)
                                          )
                                        ),
                         new Definition(Type.I32, new ID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Mod,
                                           new ID("a"),
                                           new Constant(Type.I32, 2L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("b"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Eq,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("c"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Neq,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("d"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Lt,
                                              new Constant(Type.U8, 2L),
                                              new Constant(Type.U8, 4L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("e"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Gt,
                                              new Constant(Type.U8, 3L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("f"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Leq,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("g"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Geq,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("h"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BoolOr,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("i"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BoolAnd,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("j"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitLs,
                                              new Constant(Type.U8, 4L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("k"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitRs,
                                              new Constant(Type.U8, 16L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("l"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitAnd,
                                              new Constant(Type.U8, 8L),
                                              new Constant(Type.U8, 8L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("m"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitOr,
                                              new Constant(Type.U8, 8L),
                                              new Constant(Type.U8, 4L)
                                          )
                                        ),
                         new Definition(Type.U8, new ID("n"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitXor,
                                              new Constant(Type.U8, 12L),
                                              new Constant(Type.U8, 8L)
                                          )
                                        ),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/binop.lilac");

    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseExtern() {
    Program expected = new();
    expected.AddExternFunc(new("console", "log",
                               [Type.F64], Type.Void));
    FuncDef divide = new("divide",
                         [
                           new(Type.F64, new ID("a")),
                           new(Type.F64, new ID("b")),
                         ],
                         Type.F64,
                         [
                           new Definition(Type.F64, new ID("0"),
                                          new BinaryOp(
                                            BinaryOp.Operator.Div,
                                            new ID("a"),
                                            new ID("b")
                                          )),
                           new Return(new ID("0")),
                         ]);
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.F64, new ID("1"),
                                        new Call("divide",
                                                 [
                                                   new Constant(Type.F64, 6.0),
                                                   new Constant(Type.F64, 3.3),
                                                 ])),
                         new Definition(Type.F64, new ID("ans"),
                                        new ValueExpr(new ID("1"))),
                         new VoidCall(
                           new ExternCall("console", "log",
                                          [new ID("ans")])),
                         new Return(new Constant(Type.Void, 0)),
                       ]);
    expected.AddFunc(divide);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/extern.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseFunc() {
    Program expected = new();
    FuncDef multiply = new("multiply",
                           [
                             new(Type.I32, new ID("a")),
                             new(Type.I32, new ID("b")),
                           ],
                           Type.I32,
                           [
                             new Definition(Type.I32, new ID("0"),
                                            new BinaryOp(
                                               BinaryOp.Operator.Mul,
                                               new ID("a"),
                                               new ID("b"))),
                             new Return(new ID("0")),
                           ]
                          );
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.I32, new ID("ans"),
                                        new Call("multiply",
                                                 [
                                                   new Constant(Type.I32, 3L),
                                                   new Constant(Type.I32, 5L),
                                                 ])),
                       ]);
    expected.AddFunc(multiply);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/func.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseGlobals() {
    Program expected = new();
    expected.AddGlobal(new GlobalDef(Type.I32, new("a"),
                                     new Constant(Type.I32, 2L)));
    expected.AddGlobal(new GlobalDef(Type.I32, new("b"),
                                     new Constant(Type.I32, 0L)));
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.I32, new ID("a"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 3L))),
                         new Definition(Type.I32, new ID("0"),
                                        new BinaryOp(
                                                     BinaryOp.Operator.Add,
                                                     new ID("a"),
                                                     new GlobalID("a"))),
                         new Definition(Type.I32, new GlobalID("b"),
                                        new ValueExpr(new ID("0"))),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/globals.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseJzJnz() {
    Program expected = new();
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Label("L0"),
                         new Definition(Type.I32, new ID("a"),
                                        new ValueExpr(
                                          new Constant(Type.I32, 5L))),
                         new JumpNotZero("L0", new ID("a")),
                         new JumpZero("L0", new Constant(Type.U8, 1L)),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/jz_jnz.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseLabelAndJmp() {
    Program expected = new();
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Label("L0"),
                         new Definition(Type.I32, new ID("a"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 3L))),
                         new Jump("L0"),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/label_and_jmp.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParsePhi() {
    Program expected = new();
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.I32, new ID("a"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 1L))),
                         new Definition(Type.I32, new ID("b"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 2L))),
                         new Definition(Type.I32, new ID("0"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Eq,
                                              new ID("a"),
                                              new Constant(Type.I32, 1L))),
                         new JumpZero("L0", new ID("0")),
                         new Definition(Type.I32, new ID("1"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Mul,
                                              new ID("b"),
                                              new Constant(Type.I32, 2L))),
                         new Definition(Type.I32, new ID("b"),
                                        new ValueExpr(
                                           new ID("0"))),
                         new Jump("L1"),
                         new Label("L0"),
                         new Definition(Type.I32, new ID("2"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Add,
                                              new ID("b"),
                                              new Constant(Type.I32, 1L))),
                         new Definition(Type.I32, new ID("b"),
                                        new ValueExpr(
                                           new ID("0"))),
                         new Label("L1"),
                         new Definition(Type.I32, new ID("b"),
                                        new Phi([new ID("b"),
                                                     new ID("b")])),
                         new Definition(Type.I32, new ID("c"),
                                        new ValueExpr(
                                           new ID("b"))),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/phi.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseTypes() {
    Program expected = new();
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.U8, new ID("a"),
                                        new ValueExpr(
                                          new Constant(Type.U8, 8L))),
                         new Definition(Type.U16, new ID("b"),
                                        new ValueExpr(
                                          new Constant(Type.U16, 9L))),
                         new Definition(Type.U32, new ID("c"),
                                        new ValueExpr(
                                          new Constant(Type.U32, 10L))),
                         new Definition(Type.U64, new ID("d"),
                                        new ValueExpr(
                                          new Constant(Type.U64, 11L))),
                         new Definition(Type.I8, new ID("e"),
                                        new ValueExpr(
                                          new Constant(Type.I8, -2L))),
                         new Definition(Type.I16, new ID("f"),
                                        new ValueExpr(
                                          new Constant(Type.I16, -3L))),
                         new Definition(Type.I32, new ID("g"),
                                        new ValueExpr(
                                          new Constant(Type.I32, 5L))),
                         new Definition(Type.I64, new ID("h"),
                                        new ValueExpr(
                                          new Constant(Type.I64, 9999L))),
                         new Definition(Type.F32, new ID("i"),
                                        new ValueExpr(
                                          new Constant(Type.F32, 3.14))),
                         new Definition(Type.F64, new ID("j"),
                                        new ValueExpr(
                                          new Constant(Type.F64, -1.0))),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/types.lilac");
    Assert.Equal(expected, actual);
  }

  [Fact]
  public void ParseUnop() {
    Program expected = new();
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.I16, new ID("a"),
                                        new UnaryOp(
                                          UnaryOp.Operator.Neg,
                                          new Constant(Type.I16, 2L))),
                         new Definition(Type.U8, new ID("b"),
                                        new UnaryOp(
                                          UnaryOp.Operator.BoolNot,
                                          new Constant(Type.U8, 0L))),
                         new Definition(Type.U16, new ID("c"),
                                        new UnaryOp(
                                          UnaryOp.Operator.BitNot,
                                          new Constant(Type.U16, 12L))),
                       ]);
    expected.AddFunc(main);

    Program actual =
      Frontend.Parser.ParseFile("./Resources/unop.lilac");
    Assert.Equal(expected, actual);
  }
}