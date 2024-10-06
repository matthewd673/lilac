using Lilac.CodeGen.Targets.Wasm.Instructions;
using Lilac.IL;
using Lilac.IL.Math;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.ILTests.MathTests;

public class InternalMathTests {
  [Theory]
  [InlineData(Type.I32, 0, Type.I64, 0L)]
  [InlineData(Type.U32, 0U, Type.I32, 0)]
  [InlineData(Type.F32, 0f, Type.F64, 0.0)]

  public void BinaryOpIllegalOperandTypesThrowsIllegalOperandTypeException
    (Type leftType, object leftValue, Type rightType, object rightValue) {
    Assert.Throws<IllegalOperandTypeException>(() =>
                                          InternalMath
                                            .Calculate(BinaryOp.Operator.Add,
                                              new Constant(leftType, leftValue),
                                              new Constant(rightType, rightValue))
                                          );
  }

  [Fact]
  public void BinaryOpVoidOperandThrowsIllegalOperandTypeException() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                                                 InternalMath
                                                   .Calculate(BinaryOp.Operator.Add,
                                                     new Constant(Type.Void, new DeepEqualArray<byte>()),
                                                     new Constant(Type.I32, 0)
                                              ));
    Assert.Throws<IllegalOperandTypeException>(() =>
                                                 InternalMath
                                                   .Calculate(BinaryOp.Operator.Add,
                                                     new Constant(Type.I32, 0),
                                                     new Constant(Type.Void, new DeepEqualArray<byte>())
                                              ));
    Assert.Throws<IllegalOperandTypeException>(() =>
                                                 InternalMath
                                                   .Calculate(BinaryOp.Operator.Add,
                                                     new Constant(Type.Void, new DeepEqualArray<byte>()),
                                                     new Constant(Type.Void, new DeepEqualArray<byte>())
                                              ));
  }

  [Fact]
  public void UnaryOpTypeIsVoid() {
    Assert.Throws<IllegalOperandTypeException>(() =>
                      InternalMath.Calculate(UnaryOp.Operator.Neg,
                                             new Constant(Type.Void, [0]))
                    );
  }
}
