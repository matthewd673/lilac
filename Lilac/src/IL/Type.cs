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

  public static int GetSize(this Type type) {
    return type switch {
      Type.U8 => 8,
      Type.U16 => 16,
      Type.U32 => 32,
      Type.U64 => 64,
      Type.I8 => 8,
      Type.I16 => 16,
      Type.I32 => 32,
      Type.I64 => 64,
      Type.F32 => 32,
      Type.F64 => 64,
      Type.Pointer => throw new NotSupportedException(),
      Type.Void => throw new NotSupportedException(),
      _ => throw new ArgumentOutOfRangeException(),
    };
  }
}
