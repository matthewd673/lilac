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

  public static string GetWat(this Type type) {
    return type switch {
      Type.I32 => "i32",
      Type.I64 => "i64",
      Type.F32 => "f32",
      Type.F64 => "f64",
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public static int GetSizeBytes(this Type type) {
    return type switch {
      Type.I32 => 4,
      Type.I64 => 4,
      Type.F32 => 4,
      Type.F64 => 4,
      _ => throw new ArgumentOutOfRangeException(),
    };
  }

  public static Type ToWasmType(this IL.Type type) {
    return type switch {
      IL.Type.I32 => Type.I32,
      IL.Type.I64 => Type.I64,
      IL.Type.F32 => Type.F32,
      IL.Type.F64 => Type.F64,
      IL.Type.Pointer => Runtime.PointerType,
      _ => throw new ArgumentOutOfRangeException(nameof(type),
                                                 type,
                                                 "IL type not support in Wasm"),
    };
  }

}