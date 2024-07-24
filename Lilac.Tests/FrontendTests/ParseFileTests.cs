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
}