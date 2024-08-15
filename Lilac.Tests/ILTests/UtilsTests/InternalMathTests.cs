using Lilac.IL;
using Lilac.IL.Math;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.ILTests.UtilsTests;

public class InternalMathTests {
  [Fact]
  public void BinaryOpTypeMismatch() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                      InternalMath.Calculate(BinaryOp.Operator.Add,
                                             new Constant(Type.I32, [0]),
                                             new Constant(Type.I64, [0]))
                    );
  }

  [Fact]
  public void BinaryOpLeftTypeIsVoid() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                      InternalMath.Calculate(BinaryOp.Operator.Add,
                                             new Constant(Type.Void, [0]),
                                             new Constant(Type.I64, [0]))
                    );
  }

  [Fact]
  public void BinaryOpRightTypeIsVoid() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                      InternalMath.Calculate(BinaryOp.Operator.Add,
                                             new Constant(Type.I32, [0]),
                                             new Constant(Type.Void, [0]))
                    );
  }

  [Fact]
  public void UnaryOpTypeIsVoid() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                      InternalMath.Calculate(UnaryOp.Operator.Neg,
                                             new Constant(Type.Void, [0]))
                    );
  }
}