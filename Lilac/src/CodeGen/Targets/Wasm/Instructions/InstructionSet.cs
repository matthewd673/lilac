namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public class Const(Type type, string value) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x41,
      Type.I64 => 0x42,
      Type.F32 => 0x43,
      Type.F64 => 0x44,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.const {Value}";

  public string Value { get; } = value;

  public override bool Equals(object? obj) {
    if (obj is not Const other) {
      return false;
    }

    return OpCode.Equals(other.OpCode) && Type.Equals(other.Type) &&
           Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Type, Value);
  }
}

public class Equal(Type type) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x46,
      Type.I64 => 0x51,
      Type.F32 => 0x5b,
      Type.F64 => 0x61,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.eq";
}

public class EqualZero(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x45,
      Type.I64 => 0x50,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.eqz";
}

public class NotEqual(Type type) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x47,
      Type.I64 => 0x52,
      Type.F32 => 0x5c,
      Type.F64 => 0x62,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ne";
}

public class GreaterThanSigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4a,
      Type.I64 => 0x55,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt_s";
}

public class GreaterThanUnsigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4b,
      Type.I64 => 0x56,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt_u";
}

public class GreaterThan(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5e,
      Type.F64 => 0x64,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt";
}

public class LessThanSigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x48,
      Type.I64 => 0x53,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt_s";
}

public class LessThanUnsigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x49,
      Type.I64 => 0x53,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt_u";
}

public class LessThan(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5d,
      Type.F64 => 0x63,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt";
}

public class GreaterOrEqualSigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4e,
      Type.I64 => 0x59,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge_s";
}

public class GreaterOrEqualUnsigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4f,
      Type.I64 => 0x5a,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge_u";
}

public class GreaterOrEqual(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x60,
      Type.F64 => 0x66,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge";
}

public class LessOrEqualSigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4c,
      Type.I64 => 0x57,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le_s";
}

public class LessOrEqualUnsigned(Type type)
  : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4d,
      Type.I64 => 0x58,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le_u";
}

public class LessOrEqual(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5f,
      Type.F64 => 0x65,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le";
}


public class Add(Type type) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6a,
      Type.I64 => 0x7c,
      Type.F32 => 0x92,
      Type.F64 => 0xa0,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.add";
}

public class Subtract(Type type) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6b,
      Type.I64 => 0x7d,
      Type.F32 => 0x93,
      Type.F64 => 0xa1,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.sub";
}

public class Multiply(Type type) : TypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6c,
      Type.I64 => 0x7e,
      Type.F32 => 0x94,
      Type.F64 => 0xa2,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.mul";
}

public class DivideSigned(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6d,
      Type.I64 => 0x7f,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div_s";
}

public class DivideUnsigned(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6e,
      Type.I64 => 0x80,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div_u";
}

public class Divide(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x95,
      Type.F64 => 0xa3,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div";
}

public class RemainderSigned(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6f,
      Type.I64 => 0x81,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.rem_s";
}

public class RemainderUnsigned(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x70,
      Type.I64 => 0x82,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.rem_u";
}

public class LocalGet(string variable) : VariableWasmInstruction(variable) {
  public override byte OpCode => 0x20;

  public override string Wat => $"local.get ${Variable}";
}

public class LocalSet(string variable) : VariableWasmInstruction(variable) {
  public override byte OpCode => 0x21;

  public override string Wat => $"local.set ${Variable}";
}

public class LocalTee(string variable) : VariableWasmInstruction(variable) {
  public override byte OpCode => 0x22;

  public override string Wat => $"local.tee ${Variable}";
}

public class GlobalGet(string variable) : VariableWasmInstruction(variable) {
  public override byte OpCode => 0x23;

  public override string Wat => $"global.get ${Variable}";
}

public class GlobalSet(string variable) : VariableWasmInstruction(variable) {
  public override byte OpCode => 0x24;

  public override string Wat => $"global.set ${Variable}";
}

public class ExtendI32S : WasmInstruction {
  public override byte OpCode => 0xac;

  public override string Wat => "i64.extend_i32_s";
}

public class ExtendI32U : WasmInstruction {
  public override byte OpCode => 0xad;

  public override string Wat => "i64.extend_i32_u";
}

public class WrapI64 : WasmInstruction {
  public override byte OpCode => 0xa7;

  public override string Wat => "i64.wrap_i64";
}

public class PromoteF32 : WasmInstruction {
  public override byte OpCode => 0xbb;

  public override string Wat => "f64.promote_f32";
}

public class DemoteF64 : WasmInstruction {
  public override byte OpCode => 0xb6;

  public override string Wat => "f64.demote_f64";
}

public class ConvertI32S(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb2,
      Type.F64 => 0xb7,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i32_s";
}

public class ConvertI32U(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb3,
      Type.F64 => 0xb8,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i32_u";
}

public class ConvertI64S(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb4,
      Type.F64 => 0xb9,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i64_s";
}

public class ConvertI64U(Type type) : FloatTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb5,
      Type.F64 => 0xba,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i64_u";
}

public class TruncF32S(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xa8,
      Type.I64 => 0xae,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f32_s";
}

public class TruncF32U(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xa9,
      Type.I64 => 0xaf,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f32_u";
}

public class TruncF64S(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xaa,
      Type.I64 => 0xb0,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f64_s";
}

public class TruncF64U(Type type) : IntegerTypedWasmInstruction(type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xab,
      Type.I64 => 0xb1,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f64_u";
}

public class Grow(string memory) : MemoryWasmInstruction(memory) {
  public override byte OpCode => 0x40;

  public override string Wat =>
    $"memory.grow{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Size(string memory) : MemoryWasmInstruction(memory) {
  public override byte OpCode => 0x3f;

  public override string Wat =>
    $"memory.size{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load(Type type, string? memory = null)
  : TypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x28,
      Type.I64 => 0x29,
      Type.F32 => 0x2a,
      Type.F64 => 0x2b,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load8S(Type type, string? memory = null)
  : IntegerTypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2c,
      Type.I64 => 0x30,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load8_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load8U(Type type, string? memory = null)
  : IntegerTypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2d,
      Type.I64 => 0x31,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load8_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load16S(Type type, string? memory = null)
  : IntegerTypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2c,
      Type.I64 => 0x32,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load16_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load16U(Type type, string? memory = null)
  : IntegerTypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2f,
      Type.I64 => 0x33,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load16_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load32S(string? memory = null) : MemoryWasmInstruction(memory) {
  public override byte OpCode => 0x34;

  public override string Wat =>
    $"i64.load32_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Load32U(string? memory = null)
  : MemoryWasmInstruction(memory) {
  public override byte OpCode => 0x35;

  public override string Wat =>
    $"i64.load32_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Store(Type type, string? memory = null)
  : TypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x36,
      Type.I64 => 0x37,
      Type.F32 => 0x38,
      Type.F64 => 0x39,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.store{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Store8(Type type, string? memory = null)
  : TypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x3a,
      Type.I64 => 0x3c,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.store8{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Store16(Type type, string? memory = null)
  : TypedMemoryWasmInstruction(type, memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x3b,
      Type.I64 => 0x3d,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.store16{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public class Store32(string? memory = null) : MemoryWasmInstruction(memory) {
  public override byte OpCode => 0x3e;

  public override string Wat =>
    $"i64.store32{(Memory is null ? "" : $" (memory ${Memory})")}";
}

// TODO: copy

// TODO: fill

public class Block(string label) : LabelWasmInstruction(label) {
  public override byte OpCode => 0x02;

  public override string Wat => $"block ${Label}";
}

public class Branch(string label) : LabelWasmInstruction(label) {
  public override byte OpCode => 0x0c;

  public override string Wat => $"br ${Label}";
}

public class BranchIf(string label) : LabelWasmInstruction(label) {
  public override byte OpCode => 0x0d;

  public override string Wat => $"br_if ${Label}";
}

public class Call : WasmInstruction {
  public override byte OpCode => 0x10;
  public override string Wat => $"call ${FuncName}";

  public string FuncName { get; }

  public Call(string funcName) {
    FuncName = funcName;
  }

  public override bool Equals(object? obj) {
    if (obj is not Call other) {
      return false;
    }

    return FuncName.Equals(other.FuncName);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, FuncName);
  }
}

public class End : WasmInstruction {
  public override byte OpCode => 0x0b;
  public override string Wat => "end";
}

public class If : WasmInstruction {
  public override byte OpCode => 0x04;
  public override string Wat => "if";

  public Else? ElseBranch { get; }

  public If(Else? elseBranch = null) {
    ElseBranch = elseBranch;
  }

  public override bool Equals(object? obj) {
    if (obj is not If other) {
      return false;
    }

    return ElseBranch is null && other.ElseBranch is null ||
           ElseBranch != null && ElseBranch.Equals(other.ElseBranch);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, ElseBranch);
  }
}

public class Else : WasmInstruction {
  public override byte OpCode => 0x05;
  public override string Wat => "else";
}

public class Loop(string label) : LabelWasmInstruction(label) {
  public override byte OpCode => 0x03;
  public override string Wat => $"loop ${Label}";
}

public class Return : WasmInstruction {
  public override byte OpCode => 0x0f;
  public override string Wat => "return";
}

public class EmptyType : WasmInstruction {
  public override byte OpCode => 0x40;
  public override string Wat => "nop";
}

public class Comment(string text) : WasmInstruction {
  public string Text { get; } = text;
  public override byte OpCode => throw new InvalidOperationException();
  public override string Wat => $";; {Text}";
}
