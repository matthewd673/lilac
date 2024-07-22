using Lilac.IL;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.ILTests;

public class EqualityTests {
  [Fact]
  public void ConstantsEqual() {
    Constant a = new(Type.I32, 5);
    Constant b = new(Type.I32, 5);
    Assert.Equal(a, b);
  }

  [Fact]
  public void ConstantsNotEqual() {
    Constant a = new(Type.I32, 5);
    Constant b = new(Type.I32, 6);
    Assert.NotEqual(a, b);

    Constant c = new(Type.I32, 5);
    Constant d = new(Type.I64, 5);
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void IdsEqual() {
    ID a = new("a");
    ID b = new("a");
    Assert.Equal(a, b);
  }

  [Fact]
  public void IdsNotEqual() {
    ID a = new("a");
    ID b = new("b");
    Assert.NotEqual(a, b);

    ID c = new("var");
    GlobalID d = new("var");
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void ValueExprsEqual() {
    ValueExpr a = new(new Constant(Type.F32, 3.3));
    ValueExpr b = new(new Constant(Type.F32, 3.3));
    Assert.Equal(a, b);
  }

  [Fact]
  public void ValueExprsNotEqual() {
    ValueExpr a = new(new Constant(Type.F32, 3.3));
    ValueExpr b = new(new ID("a"));
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void BinaryOpsEqual() {
    BinaryOp a = new(BinaryOp.Operator.Add,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    BinaryOp b = new(BinaryOp.Operator.Add,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    Assert.Equal(a, b);
  }

  [Fact]
  public void BinaryOpsNotEqual() {
    BinaryOp a = new(BinaryOp.Operator.Add,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    BinaryOp b = new(BinaryOp.Operator.BitAnd,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    Assert.NotEqual(a, b);

    BinaryOp c = new(BinaryOp.Operator.Mul,
                     new ID("test"),
                     new ID("a"));
    BinaryOp d = new(BinaryOp.Operator.Mul,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    Assert.NotEqual(c, d);

    BinaryOp e = new(BinaryOp.Operator.Sub,
                     new ID("a"),
                     new Constant(Type.I32, 5));
    BinaryOp f = new(BinaryOp.Operator.Sub,
                     new Constant(Type.I32, 5),
                     new ID("a"));
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void UnaryOpsEqual() {
    UnaryOp a = new(UnaryOp.Operator.Neg,
                    new ID("a"));
    UnaryOp b = new(UnaryOp.Operator.Neg,
                    new ID("a"));
    Assert.Equal(a, b);
  }

  [Fact]
  public void UnaryOpsNotEqual() {
    UnaryOp a = new(UnaryOp.Operator.Neg,
                    new ID("a"));
    UnaryOp b = new(UnaryOp.Operator.BitNot,
                    new ID("a"));
    Assert.NotEqual(a, b);

    UnaryOp c = new(UnaryOp.Operator.Neg,
                    new ID("a"));
    UnaryOp d = new(UnaryOp.Operator.Neg,
                    new ID("b"));
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void ConversionsEqual() {
    SignTruncConversion a = new(new Constant(Type.F32, 1.2), Type.F64);
    SignTruncConversion b = new(new Constant(Type.F32, 1.2), Type.F64);

    Assert.Equal(a, b);
  }

  [Fact]
  public void ConversionsNotEqual() {
    SignTruncConversion a = new(new Constant(Type.I32, 1), Type.U32);
    SignTruncConversion b = new(new Constant(Type.I32, 2), Type.U32);
    Assert.NotEqual(a, b);

    SignTruncConversion c = new(new Constant(Type.I32, 1), Type.U32);
    SignTruncConversion d = new(new Constant(Type.I32, 1), Type.U16);
    Assert.NotEqual(c, d);

    Conversion e =
      new SignExtendConversion(new Constant(Type.I32, 1), Type.I32);
    Conversion f =
      new SignTruncConversion(new Constant(Type.I32, 1), Type.I32);
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void CallsEqual() {
    Call a = new("func", []);
    Call b = new("func", []);
    Assert.Equal(a, b);

    Call c = new("func", [new ID("a")]);
    Call d = new("func", [new ID("a")]);
    Assert.Equal(c, d);
  }

  [Fact]
  public void CallsNotEqual() {
    Call a = new("func1", []);
    Call b = new("func2", []);
    Assert.NotEqual(a, b);

    Call c = new("func", [new Constant(Type.I32, 1)]);
    Call d = new("func", [new Constant(Type.I64, 1)]);
    Assert.NotEqual(c, d);

    Call e = new("func", []);
    Call f = new ExternCall("source", "func", []);
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void ExternCallsEqual() {
    ExternCall a = new("source", "func", []);
    ExternCall b = new("source", "func", []);
    Assert.Equal(a, b);

    ExternCall c = new("a", "b", [new ID("id")]);
    ExternCall d = new("a", "b", [new ID("id")]);
    Assert.Equal(c, d);
  }

  [Fact]
  public void ExternCallsNotEqual() {
    ExternCall a = new("source", "func", []);
    ExternCall b = new("source2", "func", []);
    Assert.NotEqual(a, b);

    ExternCall c = new("source", "func", []);
    ExternCall d = new("source", "func2", []);
    Assert.NotEqual(c, d);

    ExternCall e = new("a", "b", [new ID("id")]);
    ExternCall f = new("a", "b", []);
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void PhisEqual() {
    Phi a = new([]);
    Phi b = new([]);
    Assert.Equal(a, b);

    Phi c = new([new ID("a"), new ID("b")]);
    Phi d = new([new ID("a"), new ID("b")]);
    Assert.Equal(c, d);
  }

  [Fact]
  public void PhisNotEqual() {
    Phi a = new([new ID("a"), new ID("b")]);
    Phi b = new([new ID("a")]);
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void DefinitionsEqual() {
    Definition a = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Definition b = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Assert.Equal(a, b);
  }

  [Fact]
  public void DefinitionsNotEqual() {
    Definition a = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Definition b = new(Type.I16, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Assert.NotEqual(a, b);

    Definition c = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Definition d = new(Type.I8, new ID("b"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Assert.NotEqual(c, d);

    Definition e = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 5)));
    Definition f = new(Type.I8, new ID("a"),
                       new ValueExpr(new Constant(Type.I8, 6)));
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void LabelsEqual() {
    Label a = new("a");
    Label b = new("a");
    Assert.Equal(a, b);
  }

  [Fact]
  public void LabelsNotEqual() {
    Label a = new("a");
    Label b = new("b");
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void JumpsEqual() {
    Jump a = new("a");
    Jump b = new("a");
    Assert.Equal(a, b);
  }

  [Fact]
  public void JumpsNotEqual() {
    Jump a = new("a");
    Jump b = new("b");
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void CondJumpsEqual() {
    JumpZero a = new("a", new ID("a"));
    JumpZero b = new("a", new ID("a"));
    Assert.Equal(a, b);

    JumpNotZero c = new("a", new ID("a"));
    JumpNotZero d = new("a", new ID("a"));
    Assert.Equal(c, d);
  }

  [Fact]
  public void CondJumpsNotEqual() {
    JumpZero a = new("a", new ID("a"));
    JumpZero b = new("b", new ID("a"));
    Assert.NotEqual(a, b);

    JumpNotZero c = new("a", new ID("a"));
    JumpNotZero d = new("a", new ID("b"));
    Assert.NotEqual(c, d);

    CondJump e = new JumpZero("a", new ID("a"));
    CondJump f = new JumpNotZero("a", new ID("b"));
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void ReturnsEqual() {
    Return a = new(new Constant(Type.I32, 3));
    Return b = new(new Constant(Type.I32, 3));
    Assert.Equal(a, b);
  }

  [Fact]
  public void ReturnsNotEqual() {
    Return a = new(new Constant(Type.I32, 3));
    Return b = new(new ID("a"));
    Assert.NotEqual(a, b);
  }

  [Fact]
  public void VoidCallsEqual() {
    VoidCall a = new(new Call("func", []));
    VoidCall b = new(new Call("func", []));
    Assert.Equal(a, b);
  }

  [Fact]
  public void VoidCallsNotEqual() {
    VoidCall a = new(new Call("func", []));
    VoidCall b = new(new ExternCall("source", "func", []));
    Assert.NotEqual(a, b);

    VoidCall c = new(new Call("func", []));
    VoidCall d = new(new Call("func2", []));
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void InlineInstrsEqual() {
    InlineInstr a = new("target", "inst");
    InlineInstr b = new("target", "inst");
    Assert.Equal(a, b);
  }

  [Fact]
  public void InlineInstrsNotEqual() {
    InlineInstr a = new("target", "inst");
    InlineInstr b = new("target2", "inst");
    Assert.NotEqual(a, b);

    InlineInstr c = new("target", "inst");
    InlineInstr d = new("target", "inst2");
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void GlobalDefsEqual() {
    GlobalDef a = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    GlobalDef b = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    Assert.Equal(a, b);
  }

  [Fact]
  public void GlobalDefsNotEqual() {
    GlobalDef a = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    GlobalDef b = new(Type.F64, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    Assert.NotEqual(a, b);

    GlobalDef c = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    GlobalDef d = new(Type.F32, new GlobalID("b"),
                      new Constant(Type.F32, 3));
    Assert.NotEqual(c, d);

    GlobalDef e = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 3));
    GlobalDef f = new(Type.F32, new GlobalID("a"),
                      new Constant(Type.F32, 4));
    Assert.NotEqual(e, f);
  }

  [Fact]
  public void FuncDefsEqual() {
    FuncDef a = new("func", [], Type.U8, [], false);
    FuncDef b = new("func", [], Type.U8, [], false);
    Assert.Equal(a, b);

    FuncDef c = new("func", [new(Type.I8, new ID("a"))],
                    Type.U8, [], false);
    FuncDef d = new("func", [new(Type.I8, new ID("a"))],
                    Type.U8, [], false);
    Assert.Equal(c, d);

    FuncDef e = new("func", [], Type.U8, [new Label("a")],
                    false);
    FuncDef f = new("func", [], Type.U8, [new Label("a")],
                    false);
    Assert.Equal(e, f);
  }

  [Fact]
  public void FuncDefsNotEqual() {
    FuncDef a = new("func", [], Type.U8, [], false);
    FuncDef b = new("func2", [], Type.U8, [], false);
    Assert.NotEqual(a, b);

    FuncDef c = new("func", [new(Type.I8, new ID("a"))],
                    Type.U8, [], false);
    FuncDef d = new("func", [],
                    Type.U8, [], false);
    Assert.NotEqual(c, d);

    FuncDef e = new("func", [], Type.U8, [new Label("a")],
                    false);
    FuncDef f = new("func", [], Type.U8, [new Label("b")],
                    false);
    Assert.NotEqual(e, f);

    FuncDef g = new("func", [], Type.U8, [], false);
    FuncDef h = new("func", [], Type.I8, [], false);
    Assert.NotEqual(g, h);

    FuncDef i = new("func", [], Type.U8, [], false);
    FuncDef j = new("func", [], Type.U8, [], true);
    Assert.NotEqual(i, j);
  }

  [Fact]
  public void FuncParamsEqual() {
    FuncParam a = new(Type.F32, new ID("a"));
    FuncParam b = new(Type.F32, new ID("a"));
    Assert.Equal(a, b);
  }

  [Fact]
  public void FuncParamsNotEqual() {
    FuncParam a = new(Type.F32, new ID("a"));
    FuncParam b = new(Type.F64, new ID("a"));
    Assert.NotEqual(a, b);

    FuncParam c = new(Type.F32, new ID("a"));
    FuncParam d = new(Type.F32, new ID("b"));
    Assert.NotEqual(c, d);
  }

  [Fact]
  public void ExternFuncDefsEqual() {
    ExternFuncDef a = new("source", "func", [], Type.I32);
    ExternFuncDef b = new("source", "func", [], Type.I32);
    Assert.Equal(a, b);

    ExternFuncDef c = new("source", "func", [Type.I32, Type.I64],
                          Type.I32);
    ExternFuncDef d = new("source", "func", [Type.I32, Type.I64],
                          Type.I32);
    Assert.Equal(c, d);
  }

  [Fact]
  public void ExternFuncDefsNotEqual() {
    ExternFuncDef a = new("source", "func", [], Type.I32);
    ExternFuncDef b = new("source2", "func", [], Type.I32);
    Assert.NotEqual(a, b);

    ExternFuncDef c = new("source", "func", [], Type.I32);
    ExternFuncDef d = new("source", "func2", [], Type.I32);
    Assert.NotEqual(c, d);

    ExternFuncDef e = new("source", "func", [], Type.I32);
    ExternFuncDef f = new("source", "func", [Type.U16], Type.I32);
    Assert.NotEqual(e, f);

    ExternFuncDef g = new("source", "func", [Type.I32, Type.I64],
                          Type.I32);
    ExternFuncDef h = new("source", "func", [Type.I32, Type.I64],
                          Type.F32);
    Assert.NotEqual(g, h);
  }
}