using Lilac.IL;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.ILTests;

public class CloneTests {
  [Fact]
  public void CloneConstant() {
    Constant a = new(Type.I32, [5]);
    Constant b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneId() {
    LocalID a = new("var");
    LocalID b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneValueExpr() {
    ValueExpr a = new(new Constant(Type.F64, [0]));
    ValueExpr b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneBinaryOp() {
    BinaryOp a = new(BinaryOp.Operator.Mul,
                     new Constant(Type.I32, [3]),
                     new Constant(Type.I32, [5]));
    BinaryOp b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneUnaryOp() {
    UnaryOp a = new(UnaryOp.Operator.BitNot, new LocalID("var"));
    UnaryOp b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneConversion() {
    IntToFloatConversion a = new(new Constant(Type.I32, [5]), Type.F32);
    IntToFloatConversion b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneCall() {
    Call a = new("func", [new LocalID("arg")]);
    Call b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneExternCall() {
    ExternCall a = new("source", "func",
                       [new Constant(Type.I32, [5])]);
    ExternCall b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void ClonePhi() {
    Phi a = new([new LocalID("a"), new LocalID("b")]);
    Phi b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneLoad() {
    Load a = new(Type.I32, new Constant(Type.Pointer, [0]));
    Load b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneStackAlloc() {
    StackAlloc a = new(new SizeOfPrimitive(Type.I32));
    StackAlloc b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneDefinition() {
    Definition a = new(Type.I32, new LocalID("var"),
                       new ValueExpr(new Constant(Type.I32, [5])));
    Definition b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneLabel() {
    Label a = new("L1");
    Label b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneJump() {
    Jump a = new("L1");
    Jump b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneJumpZero() {
    JumpZero a = new("L1", new Constant(Type.I32, [0]));
    JumpZero b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneJumpNotZero() {
    JumpNotZero a = new("L1", new Constant(Type.I32, [1]));
    JumpNotZero b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneReturn() {
    Return a = new(new LocalID("var"));
    Return b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneVoidCall() {
    VoidCall a = new(new Call("func", [
                                        new LocalID("a"),
                                        new LocalID("b")
                                      ]));
    VoidCall b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneInlineInstr() {
    InlineInstr a = new("wasm",
                        new CodeGen.Targets.Wasm.Instructions.Add(
                         CodeGen.Targets.Wasm.Instructions.Type.I32));
    InlineInstr b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneStore() {
    Store a = new(Type.I32,
                  new LocalID("a"),
                  new Constant(Type.Pointer, [0]));
    Store b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneGlobalDef() {
    GlobalDef a = new(Type.F32, new GlobalID("global"),
                      new Constant(Type.F32, [0]));
    GlobalDef b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneFuncDef() {
    FuncDef a = new("func", [new(Type.I32, new LocalID("p"))],
                    Type.Void, [new Label("L1"), new Jump("L1")],
                    true);
    FuncDef b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneFuncParam() {
    FuncParam a = new(Type.U8, new LocalID("var"));
    FuncParam b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }

  [Fact]
  public void CloneExternFuncDef() {
    ExternFuncDef a = new("source", "func", [Type.I16, Type.U8], Type.Void);
    ExternFuncDef b = a.Clone();

    Assert.False(a == b);
    Assert.Equal(a, b);
  }
}