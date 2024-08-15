namespace Lilac.IL;

public enum Type {
  U8,
  U16,
  U32,
  U64,
  I8,
  I16,
  I32,
  I64,
  F32,
  F64,
  Pointer,
  Void,
}

public static class TypeMethods {
  public static bool IsUnsigned(this Type type) {
    return type switch {
      Type.U8 or Type.U16 or Type.U32 or Type.U64 => true,
      _ => false,
    };
  }

  public static bool IsSigned(this Type type) {
    return type switch {
      Type.I8 or Type.I16 or Type.I32 or Type.I64 => true,
      _ => false,
    };
  }

  public static bool IsInteger(this Type type) {
    return type.IsUnsigned() || type.IsSigned();
  }

  public static bool IsFloat(this Type type) {
    return type switch {
      Type.F32 or Type.F64 => true,
      _ => false,
    };
  }

  public static bool IsNumeric(this Type type) {
    return type.IsInteger() || type.IsFloat();
  }

  public static bool IsPointer(this Type type) {
    return type switch {
      Type.Pointer => true,
      _ => false,
    };
  }

  public static bool IsVoid(this Type type) {
    return type switch {
      Type.Void => true,
      _ => false,
    };
  }

  public static int GetSizeBytes(this Type type) {
    return type switch {
      Type.U8 => 1,
      Type.U16 => 2,
      Type.U32 => 4,
      Type.U64 => 8,
      Type.I8 => 1,
      Type.I16 => 2,
      Type.I32 => 4,
      Type.I64 => 8,
      Type.F32 => 4,
      Type.F64 => 8,
      Type.Pointer => throw new NotSupportedException(),
      Type.Void => throw new NotSupportedException(),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public static long GetMinimumValue(this Type type) {
    return type switch {
      Type.U8 => 0,
      Type.U16 => 0,
      Type.U32 => 0,
      Type.U64 => 0,
      Type.I8 => -128,
      Type.I16 => -32_768,
      Type.I32 => -2_147_483_648,
      Type.I64 => -9_223_372_036_854_775_808,
      Type.F32 => throw new NotImplementedException(), // TODO
      Type.F64 => throw new NotImplementedException(), // TODO
      Type.Pointer => throw new NotSupportedException(),
      Type.Void => throw new NotSupportedException(),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public static ulong GetMaximumValue(this Type type) {
    return type switch {
      Type.U8 => 255,
      Type.U16 => 65_535,
      Type.U32 => 4_294_967_295,
      Type.U64 => 18_446_744_073_709_551_615,
      Type.I8 => 127,
      Type.I16 => 32_767,
      Type.I32 => 2_147_483_647,
      Type.I64 => 9_223_372_036_854_775_807,
      Type.F32 => throw new NotImplementedException(), // TODO
      Type.F64 => throw new NotImplementedException(), // TODO
      Type.Pointer => throw new NotSupportedException(),
      Type.Void => throw new NotSupportedException(),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }
}
