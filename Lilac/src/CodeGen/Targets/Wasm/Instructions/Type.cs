namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public enum Type {
  I32,
  I64,
  F32,
  F64,
}

public static class TypeMethods {
  public static bool IsInteger(this Type type) {
    return type switch {
      Type.I32 or Type.I64 => true,
      _ => false,
    };
  }

  public static bool IsFloat(this Type type) {
    return type switch {
      Type.F32 or Type.F64 => true,
      _ => false,
    };
  }

  public static string ToString(this Type type) {
    return type switch {
      Type.I32 => "i32",
      Type.I64 => "i64",
      Type.F32 => "f32",
      Type.F64 => "f64",
      _ => throw new ArgumentOutOfRangeException(),
    };
  }
}