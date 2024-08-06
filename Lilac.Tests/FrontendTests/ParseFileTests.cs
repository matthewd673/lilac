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
                         new Definition(Type.I32, new LocalID("a"),
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
                         new Definition(Type.I32, new LocalID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Add,
                                           new Constant(Type.I32, 12L),
                                           new Constant(Type.I32, 6L)
                                          )
                                        ),
                         new Definition(Type.I32, new LocalID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Sub,
                                           new LocalID("a"),
                                           new Constant(Type.I32, 0L)
                                          )
                                        ),
                         new Definition(Type.I32, new LocalID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Mul,
                                           new LocalID("a"),
                                           new Constant(Type.I32, -2L)
                                          )
                                        ),
                         new Definition(Type.I32, new LocalID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Div,
                                           new LocalID("a"),
                                           new Constant(Type.I32, -2L)
                                          )
                                        ),
                         new Definition(Type.I32, new LocalID("a"),
                                        new BinaryOp(
                                           BinaryOp.Operator.Mod,
                                           new LocalID("a"),
                                           new Constant(Type.I32, 2L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("b"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Eq,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("c"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Neq,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("d"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Lt,
                                              new Constant(Type.U8, 2L),
                                              new Constant(Type.U8, 4L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("e"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Gt,
                                              new Constant(Type.U8, 3L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("f"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Leq,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("g"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Geq,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("h"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BoolOr,
                                              new Constant(Type.U8, 1L),
                                              new Constant(Type.U8, 0L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("i"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BoolAnd,
                                              new Constant(Type.U8, 0L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("j"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitLs,
                                              new Constant(Type.U8, 4L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("k"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitRs,
                                              new Constant(Type.U8, 16L),
                                              new Constant(Type.U8, 1L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("l"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitAnd,
                                              new Constant(Type.U8, 8L),
                                              new Constant(Type.U8, 8L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("m"),
                                        new BinaryOp(
                                              BinaryOp.Operator.BitOr,
                                              new Constant(Type.U8, 8L),
                                              new Constant(Type.U8, 4L)
                                          )
                                        ),
                         new Definition(Type.U8, new LocalID("n"),
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
                           new(Type.F64, new LocalID("a")),
                           new(Type.F64, new LocalID("b")),
                         ],
                         Type.F64,
                         [
                           new Definition(Type.F64, new LocalID("0"),
                                          new BinaryOp(
                                            BinaryOp.Operator.Div,
                                            new LocalID("a"),
                                            new LocalID("b")
                                          )),
                           new Return(new LocalID("0")),
                         ]);
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.F64, new LocalID("1"),
                                        new Call("divide",
                                                 [
                                                   new Constant(Type.F64, 6.0),
                                                   new Constant(Type.F64, 3.3),
                                                 ])),
                         new Definition(Type.F64, new LocalID("ans"),
                                        new ValueExpr(new LocalID("1"))),
                         new VoidCall(
                           new ExternCall("console", "log",
                                          [new LocalID("ans")])),
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
                             new(Type.I32, new LocalID("a")),
                             new(Type.I32, new LocalID("b")),
                           ],
                           Type.I32,
                           [
                             new Definition(Type.I32, new LocalID("0"),
                                            new BinaryOp(
                                               BinaryOp.Operator.Mul,
                                               new LocalID("a"),
                                               new LocalID("b"))),
                             new Return(new LocalID("0")),
                           ]
                          );
    FuncDef main = new("main", [], Type.Void,
                       [
                         new Definition(Type.I32, new LocalID("ans"),
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
                         new Definition(Type.I32, new LocalID("a"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 3L))),
                         new Definition(Type.I32, new LocalID("0"),
                                        new BinaryOp(
                                                     BinaryOp.Operator.Add,
                                                     new LocalID("a"),
                                                     new GlobalID("a"))),
                         new Definition(Type.I32, new GlobalID("b"),
                                        new ValueExpr(new LocalID("0"))),
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
                         new Definition(Type.I32, new LocalID("a"),
                                        new ValueExpr(
                                          new Constant(Type.I32, 5L))),
                         new JumpNotZero("L0", new LocalID("a")),
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
                         new Definition(Type.I32, new LocalID("a"),
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
                         new Definition(Type.I32, new LocalID("a"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 1L))),
                         new Definition(Type.I32, new LocalID("b"),
                                        new ValueExpr(
                                           new Constant(Type.I32, 2L))),
                         new Definition(Type.I32, new LocalID("0"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Eq,
                                              new LocalID("a"),
                                              new Constant(Type.I32, 1L))),
                         new JumpZero("L0", new LocalID("0")),
                         new Definition(Type.I32, new LocalID("1"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Mul,
                                              new LocalID("b"),
                                              new Constant(Type.I32, 2L))),
                         new Definition(Type.I32, new LocalID("b"),
                                        new ValueExpr(
                                           new LocalID("0"))),
                         new Jump("L1"),
                         new Label("L0"),
                         new Definition(Type.I32, new LocalID("2"),
                                        new BinaryOp(
                                              BinaryOp.Operator.Add,
                                              new LocalID("b"),
                                              new Constant(Type.I32, 1L))),
                         new Definition(Type.I32, new LocalID("b"),
                                        new ValueExpr(
                                           new LocalID("0"))),
                         new Label("L1"),
                         new Definition(Type.I32, new LocalID("b"),
                                        new Phi([new LocalID("b"),
                                                     new LocalID("b")])),
                         new Definition(Type.I32, new LocalID("c"),
                                        new ValueExpr(
                                           new LocalID("b"))),
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
                         new Definition(Type.U8, new LocalID("a"),
                                        new ValueExpr(
                                          new Constant(Type.U8, 8L))),
                         new Definition(Type.U16, new LocalID("b"),
                                        new ValueExpr(
                                          new Constant(Type.U16, 9L))),
                         new Definition(Type.U32, new LocalID("c"),
                                        new ValueExpr(
                                          new Constant(Type.U32, 10L))),
                         new Definition(Type.U64, new LocalID("d"),
                                        new ValueExpr(
                                          new Constant(Type.U64, 11L))),
                         new Definition(Type.I8, new LocalID("e"),
                                        new ValueExpr(
                                          new Constant(Type.I8, -2L))),
                         new Definition(Type.I16, new LocalID("f"),
                                        new ValueExpr(
                                          new Constant(Type.I16, -3L))),
                         new Definition(Type.I32, new LocalID("g"),
                                        new ValueExpr(
                                          new Constant(Type.I32, 5L))),
                         new Definition(Type.I64, new LocalID("h"),
                                        new ValueExpr(
                                          new Constant(Type.I64, 9999L))),
                         new Definition(Type.F32, new LocalID("i"),
                                        new ValueExpr(
                                          new Constant(Type.F32, 3.14))),
                         new Definition(Type.F64, new LocalID("j"),
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
                         new Definition(Type.I16, new LocalID("a"),
                                        new UnaryOp(
                                          UnaryOp.Operator.Neg,
                                          new Constant(Type.I16, 2L))),
                         new Definition(Type.U8, new LocalID("b"),
                                        new UnaryOp(
                                          UnaryOp.Operator.BoolNot,
                                          new Constant(Type.U8, 0L))),
                         new Definition(Type.U16, new LocalID("c"),
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