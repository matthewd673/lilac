using System.Buffers.Binary;

namespace Lilac.IL.Math;

public static class InternalMath {
  public static Constant Calculate(BinaryOp.Operator op,
                                   Constant left,
                                   Constant right) {
    if (!left.Type.Equals(right.Type) || left.Type.IsVoid()) {
      throw new IllegalOperandTypeException();
    }

    Type type = left.Type; // because both must match

    byte[] lArr = left.Value.Array;
    byte[] rArr = right.Value.Array;

    byte[] value = op switch {
      BinaryOp.Operator.Add => BinaryOpAdd(type, lArr, rArr),
      BinaryOp.Operator.Sub => BinaryOpSub(type, lArr, rArr),
      BinaryOp.Operator.Mul => BinaryOpMul(type, lArr, rArr),
      BinaryOp.Operator.Div => BinaryOpDiv(type, lArr, rArr),
      BinaryOp.Operator.Mod => BinaryOpMod(type, lArr, rArr),
      BinaryOp.Operator.Eq => BinaryOpEq(type, lArr, rArr),
      BinaryOp.Operator.Neq => BinaryOpNeq(type, lArr, rArr),
      BinaryOp.Operator.Lt => throw new NotImplementedException(),
      BinaryOp.Operator.Gt => throw new NotImplementedException(),
      BinaryOp.Operator.Leq => throw new NotImplementedException(),
      BinaryOp.Operator.Geq => throw new NotImplementedException(),
      BinaryOp.Operator.BoolAnd =>
        BinaryOpBoolAnd(type, lArr, rArr),
      BinaryOp.Operator.BoolOr =>
        BinaryOpBoolOr(type, lArr, rArr),
      BinaryOp.Operator.BitLs => throw new NotImplementedException(),
      BinaryOp.Operator.BitRs => throw new NotImplementedException(),
      BinaryOp.Operator.BitAnd => throw new NotImplementedException(),
      BinaryOp.Operator.BitOr => throw new NotImplementedException(),
      BinaryOp.Operator.BitXor => throw new NotImplementedException(),
      _ => throw new ArgumentOutOfRangeException(),
    };

    return new Constant(type, value);
  }

  private static byte[] BinaryOpAdd(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];

    switch (type) {
      case Type.U8:
        ans[0] = (byte)(a[0] + b[0]);
        break;
      case Type.I8:
        ans[0] = (byte)((sbyte)a[0] + (sbyte)b[0]);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(
          ans,
          (ushort)(BinaryPrimitives.ReadUInt16LittleEndian(a) +
          BinaryPrimitives.ReadUInt16LittleEndian(b)));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(
          ans,
          (short)(BinaryPrimitives.ReadInt16LittleEndian(a) +
          BinaryPrimitives.ReadInt16LittleEndian(b)));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt32LittleEndian(a) +
          BinaryPrimitives.ReadUInt32LittleEndian(b));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadInt32LittleEndian(a) +
          BinaryPrimitives.ReadInt32LittleEndian(b));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt64LittleEndian(a) +
          BinaryPrimitives.ReadUInt64LittleEndian(b));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadInt64LittleEndian(a) +
          BinaryPrimitives.ReadInt64LittleEndian(b));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(
          ans,
          BinaryPrimitives.ReadSingleLittleEndian(a) +
          BinaryPrimitives.ReadSingleLittleEndian(b));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(
          ans,
          BinaryPrimitives.ReadDoubleLittleEndian(a) +
          BinaryPrimitives.ReadDoubleLittleEndian(b));
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return ans;
  }

  private static byte[] BinaryOpSub(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];

    switch (type) {
      case Type.U8:
        ans[0] = (byte)(a[0] - b[0]);
        break;
      case Type.I8:
        ans[0] = (byte)((sbyte)a[0] - (sbyte)b[0]);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(
          ans,
          (ushort)(BinaryPrimitives.ReadUInt16LittleEndian(a) -
          BinaryPrimitives.ReadUInt16LittleEndian(b)));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(
          ans,
          (short)(BinaryPrimitives.ReadInt16LittleEndian(a) -
          BinaryPrimitives.ReadInt16LittleEndian(b)));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt32LittleEndian(a) -
          BinaryPrimitives.ReadUInt32LittleEndian(b));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadInt32LittleEndian(a) -
          BinaryPrimitives.ReadInt32LittleEndian(b));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt64LittleEndian(a) -
          BinaryPrimitives.ReadUInt64LittleEndian(b));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadInt64LittleEndian(a) -
          BinaryPrimitives.ReadInt64LittleEndian(b));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(
          ans,
          BinaryPrimitives.ReadSingleLittleEndian(a) -
          BinaryPrimitives.ReadSingleLittleEndian(b));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(
          ans,
          BinaryPrimitives.ReadDoubleLittleEndian(a) -
          BinaryPrimitives.ReadDoubleLittleEndian(b));
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return ans;
  }

  private static byte[] BinaryOpMul(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];

    switch (type) {
      case Type.U8:
        ans[0] = (byte)(a[0] * b[0]);
        break;
      case Type.I8:
        ans[0] = (byte)((sbyte)a[0] * (sbyte)b[0]);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(
          ans,
          (ushort)(BinaryPrimitives.ReadUInt16LittleEndian(a) *
          BinaryPrimitives.ReadUInt16LittleEndian(b)));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(
          ans,
          (short)(BinaryPrimitives.ReadInt16LittleEndian(a) *
          BinaryPrimitives.ReadInt16LittleEndian(b)));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt32LittleEndian(a) *
          BinaryPrimitives.ReadUInt32LittleEndian(b));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadInt32LittleEndian(a) *
          BinaryPrimitives.ReadInt32LittleEndian(b));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt64LittleEndian(a) *
          BinaryPrimitives.ReadUInt64LittleEndian(b));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadInt64LittleEndian(a) *
          BinaryPrimitives.ReadInt64LittleEndian(b));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(
          ans,
          BinaryPrimitives.ReadSingleLittleEndian(a) *
          BinaryPrimitives.ReadSingleLittleEndian(b));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(
          ans,
          BinaryPrimitives.ReadDoubleLittleEndian(a) *
          BinaryPrimitives.ReadDoubleLittleEndian(b));
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return ans;
  }

  private static byte[] BinaryOpDiv(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];

    switch (type) {
      case Type.U8:
        ans[0] = (byte)(a[0] / b[0]);
        break;
      case Type.I8:
        ans[0] = (byte)((sbyte)a[0] / (sbyte)b[0]);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(
          ans,
          (ushort)(BinaryPrimitives.ReadUInt16LittleEndian(a) /
          BinaryPrimitives.ReadUInt16LittleEndian(b)));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(
          ans,
          (short)(BinaryPrimitives.ReadInt16LittleEndian(a) /
          BinaryPrimitives.ReadInt16LittleEndian(b)));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt32LittleEndian(a) /
          BinaryPrimitives.ReadUInt32LittleEndian(b));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadInt32LittleEndian(a) /
          BinaryPrimitives.ReadInt32LittleEndian(b));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt64LittleEndian(a) /
          BinaryPrimitives.ReadUInt64LittleEndian(b));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadInt64LittleEndian(a) /
          BinaryPrimitives.ReadInt64LittleEndian(b));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(
          ans,
          BinaryPrimitives.ReadSingleLittleEndian(a) /
          BinaryPrimitives.ReadSingleLittleEndian(b));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(
          ans,
          BinaryPrimitives.ReadDoubleLittleEndian(a) /
          BinaryPrimitives.ReadDoubleLittleEndian(b));
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return ans;
  }

  private static byte[] BinaryOpMod(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];

    switch (type) {
      case Type.U8:
        ans[0] = (byte)(a[0] % b[0]);
        break;
      case Type.I8:
        ans[0] = (byte)((sbyte)a[0] % (sbyte)b[0]);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(
          ans,
          (ushort)(BinaryPrimitives.ReadUInt16LittleEndian(a) %
          BinaryPrimitives.ReadUInt16LittleEndian(b)));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(
          ans,
          (short)(BinaryPrimitives.ReadInt16LittleEndian(a) %
          BinaryPrimitives.ReadInt16LittleEndian(b)));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt32LittleEndian(a) %
          BinaryPrimitives.ReadUInt32LittleEndian(b));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(
          ans,
          BinaryPrimitives.ReadInt32LittleEndian(a) %
          BinaryPrimitives.ReadInt32LittleEndian(b));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadUInt64LittleEndian(a) %
          BinaryPrimitives.ReadUInt64LittleEndian(b));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(
          ans,
          BinaryPrimitives.ReadInt64LittleEndian(a) %
          BinaryPrimitives.ReadInt64LittleEndian(b));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(
          ans,
          BinaryPrimitives.ReadSingleLittleEndian(a) %
          BinaryPrimitives.ReadSingleLittleEndian(b));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(
          ans,
          BinaryPrimitives.ReadDoubleLittleEndian(a) %
          BinaryPrimitives.ReadDoubleLittleEndian(b));
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return ans;
  }

  private static byte[] BinaryOpEq(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];
    ans[0] = (byte)(a.SequenceEqual(b) ? 0x1 : 0x0);
    return ans;
  }

  private static byte[] BinaryOpNeq(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];
    ans[0] = (byte)(a.SequenceEqual(b) ? 0x0 : 0x1);
    return ans;
  }

  private static byte[] BinaryOpBoolAnd(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];
    ans[0] = (byte)(!IsZero(a) && !IsZero(b) ? 0x1 : 0x0);
    return ans;
  }

  private static byte[] BinaryOpBoolOr(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a, b);

    byte[] ans = new byte[a.Length];
    ans[0] = (byte)(!IsZero(a) || !IsZero(b) ? 0x1 : 0x0);
    return ans;
  }

  public static Constant Calculate(UnaryOp.Operator op, Constant value) {
    if (value.Type.IsVoid()) {
      throw new IllegalOperandTypeException();
    }

    return new(value.Type, new DeepEqualArray<byte>([])); // TODO: TEMP!
  }

  /// <summary>
  /// Check if all bits in a byte array are zero. This can be used to check if
  /// an integer value is equal to zero. NOTE: This function will return
  /// <c>false</c> for floating-point values of <c>-0.0</c>.
  /// </summary>
  /// <param name="bytes">The array of bytes to check.</param>
  /// <returns>
  ///   <c>true</c> if all bits in the array of bytes are 0.
  ///   <c>false</c> otherwise.
  /// </returns>
  public static bool IsZero(byte[] bytes) => !bytes.Where(b => b != 0).Any();

  /// <summary>
  /// Get the number of bytes required to represent a value of the given numeric
  /// type.
  /// </summary>
  /// <param name="type">The numeric type to get the byte length for.</param>
  /// <returns>The required length of the type's byte array.</returns>
  /// <exception cref="NotSupportedException">
  /// If the type is not a constant size numeric type (e.g. Void or Pointer).
  /// </exception>
  public static int ByteLength(Type type) => type switch {
    Type.U8 or Type.I8 => 1,
    Type.U16 or Type.I16 => 2,
    Type.U32 or Type.I32 => 4,
    Type.U64 or Type.I64 => 8,
    Type.F32 => 4,
    Type.F64 => 8,
    _ => throw new NotSupportedException(),
  };

  /// <summary>
  /// Get the binary representation of zero for a given numeric type. This will
  /// return <c>+0.0</c> for floating-point types.
  /// </summary>
  /// <param name="type">The type to get zero for.</param>
  /// <returns>
  ///   A byte array containing the binary representation of zero for the given
  ///   numeric type.
  /// </returns>
  /// <exception cref="NotSupportedException">
  ///   If the given type is not a numeric type.
  /// </exception>
  public static byte[] GetZero(Type type) => type switch {
    Type.U8 or Type.I8 => [0],
    Type.U16 or Type.I16 => [0, 0],
    Type.U32 or Type.I32 or Type.F32 => [0, 0, 0, 0],
    Type.U64 or Type.I64 or Type.F64 => [0, 0, 0, 0, 0, 0, 0, 0],
    _ => throw new NotSupportedException(),
  };

  private static void AssertValueInvariants(Type type, byte[] bytes) {
    if (bytes.Length != ByteLength(type)) {
      throw new IllegalValueException();
    }
  }

  private static void AssertValueInvariants(Type type, byte[] a, byte[] b) {
    AssertValueInvariants(type, a);
    AssertValueInvariants(type, b);
  }
}
