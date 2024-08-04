namespace Lilac.IL;

public static class InternalMath {
  public static Constant Calculate(BinaryOp.Operator op,
                                   Constant left,
                                   Constant right) {
    if (!left.Type.Equals(right.Type) || left.Type.IsVoid()) {
      throw new Exception(); // TODO: nice exception
    }

    return new(left.Type, 0); // TODO: TEMP!
  }

  public static Constant Calculate(UnaryOp.Operator op, Constant value) {
    if (value.Type.IsVoid()) {
      throw new Exception(); // TODO: nice exception
    }

    return new(value.Type, 0); // TODO: TEMP!
  }
}