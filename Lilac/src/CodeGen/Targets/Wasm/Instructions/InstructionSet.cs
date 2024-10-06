namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public record Const(Type Type, string Value) : TypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x41,
      Type.I64 => 0x42,
      Type.F32 => 0x43,
      Type.F64 => 0x44,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.const {Value}";

  public string Value { get; } = Value;
}

public record Equal(Type Type) : TypedWasmInstruction(Type) {
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

public record EqualZero(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x45,
      Type.I64 => 0x50,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.eqz";
}

public record NotEqual(Type Type) : TypedWasmInstruction(Type) {
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

public record GreaterThanSigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4a,
      Type.I64 => 0x55,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt_s";
}

public record GreaterThanUnsigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4b,
      Type.I64 => 0x56,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt_u";
}

public record GreaterThan(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5e,
      Type.F64 => 0x64,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.gt";
}

public record LessThanSigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x48,
      Type.I64 => 0x53,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt_s";
}

public record LessThanUnsigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x49,
      Type.I64 => 0x53,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt_u";
}

public record LessThan(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5d,
      Type.F64 => 0x63,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.lt";
}

public record GreaterOrEqualSigned(Type Type)
  : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4e,
      Type.I64 => 0x59,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge_s";
}

public record GreaterOrEqualUnsigned(Type Type)
  : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4f,
      Type.I64 => 0x5a,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge_u";
}

public record GreaterOrEqual(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x60,
      Type.F64 => 0x66,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.ge";
}

public record LessOrEqualSigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4c,
      Type.I64 => 0x57,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le_s";
}

public record LessOrEqualUnsigned(Type Type)
  : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x4d,
      Type.I64 => 0x58,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le_u";
}

public record LessOrEqual(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x5f,
      Type.F64 => 0x65,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.le";
}

public record Add(Type Type) : TypedWasmInstruction(Type) {
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

public record Subtract(Type Type) : TypedWasmInstruction(Type) {
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

public record Multiply(Type Type) : TypedWasmInstruction(Type) {
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

public record DivideSigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6d,
      Type.I64 => 0x7f,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div_s";
}

public record DivideUnsigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6e,
      Type.I64 => 0x80,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div_u";
}

public record Divide(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0x95,
      Type.F64 => 0xa3,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.div";
}

public record RemainderSigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x6f,
      Type.I64 => 0x81,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.rem_s";
}

public record RemainderUnsigned(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x70,
      Type.I64 => 0x82,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.rem_u";
}

public record LocalGet(string Variable) : VariableWasmInstruction(Variable) {
  public override byte OpCode => 0x20;

  public override string Wat => $"local.get ${Variable}";
}

public record LocalSet(string Variable) : VariableWasmInstruction(Variable) {
  public override byte OpCode => 0x21;

  public override string Wat => $"local.set ${Variable}";
}

public record LocalTee(string Variable) : VariableWasmInstruction(Variable) {
  public override byte OpCode => 0x22;

  public override string Wat => $"local.tee ${Variable}";
}

public record GlobalGet(string Variable) : VariableWasmInstruction(Variable) {
  public override byte OpCode => 0x23;

  public override string Wat => $"global.get ${Variable}";
}

public record GlobalSet(string Variable) : VariableWasmInstruction(Variable) {
  public override byte OpCode => 0x24;

  public override string Wat => $"global.set ${Variable}";
}

public record ExtendI32S : WasmInstruction {
  public override byte OpCode => 0xac;

  public override string Wat => "i64.extend_i32_s";
}

public record ExtendI32U : WasmInstruction {
  public override byte OpCode => 0xad;

  public override string Wat => "i64.extend_i32_u";
}

public record WrapI64 : WasmInstruction {
  public override byte OpCode => 0xa7;

  public override string Wat => "i64.wrap_i64";
}

public record PromoteF32 : WasmInstruction {
  public override byte OpCode => 0xbb;

  public override string Wat => "f64.promote_f32";
}

public record DemoteF64 : WasmInstruction {
  public override byte OpCode => 0xb6;

  public override string Wat => "f64.demote_f64";
}

public record ConvertI32S(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb2,
      Type.F64 => 0xb7,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i32_s";
}

public record ConvertI32U(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb3,
      Type.F64 => 0xb8,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i32_u";
}

public record ConvertI64S(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb4,
      Type.F64 => 0xb9,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i64_s";
}

public record ConvertI64U(Type Type) : FloatTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.F32 => 0xb5,
      Type.F64 => 0xba,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.convert_i64_u";
}

public record TruncF32S(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xa8,
      Type.I64 => 0xae,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f32_s";
}

public record TruncF32U(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xa9,
      Type.I64 => 0xaf,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f32_u";
}

public record TruncF64S(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xaa,
      Type.I64 => 0xb0,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f64_s";
}

public record TruncF64U(Type Type) : IntegerTypedWasmInstruction(Type) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0xab,
      Type.I64 => 0xb1,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat => $"{Type.GetWat()}.trunc_f64_u";
}

public record Grow(string Memory) : MemoryWasmInstruction(Memory) {
  public override byte OpCode => 0x40;

  public override string Wat =>
    $"memory.grow{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Size(string Memory) : MemoryWasmInstruction(Memory) {
  public override byte OpCode => 0x3f;

  public override string Wat =>
    $"memory.size{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load(Type Type, string? Memory = null)
  : TypedMemoryWasmInstruction(Type, Memory) {
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

public record Load8S(Type Type, string? Memory = null)
  : IntegerTypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2c,
      Type.I64 => 0x30,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load8_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load8U(Type Type, string? Memory = null)
  : IntegerTypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2d,
      Type.I64 => 0x31,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load8_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load16S(Type Type, string? Memory = null)
  : IntegerTypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2c,
      Type.I64 => 0x32,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load16_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load16U(Type Type, string? Memory = null)
  : IntegerTypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x2f,
      Type.I64 => 0x33,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.load16_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load32S(string? Memory = null) : MemoryWasmInstruction(Memory) {
  public override byte OpCode => 0x34;

  public override string Wat =>
    $"i64.load32_s{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Load32U(string? Memory = null)
  : MemoryWasmInstruction(Memory) {
  public override byte OpCode => 0x35;

  public override string Wat =>
    $"i64.load32_u{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Store(Type Type, string? Memory = null)
  : TypedMemoryWasmInstruction(Type, Memory) {
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

public record Store8(Type Type, string? Memory = null)
  : TypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x3a,
      Type.I64 => 0x3c,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.store8{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Store16(Type Type, string? Memory = null)
  : TypedMemoryWasmInstruction(Type, Memory) {
  public override byte OpCode =>
    Type switch {
      Type.I32 => 0x3b,
      Type.I64 => 0x3d,
      _ => throw new ArgumentOutOfRangeException(),
    };

  public override string Wat =>
    $"{Type.GetWat()}.store16{(Memory is null ? "" : $" (memory ${Memory})")}";
}

public record Store32(string? Memory = null) : MemoryWasmInstruction(Memory) {
  public override byte OpCode => 0x3e;

  public override string Wat =>
    $"i64.store32{(Memory is null ? "" : $" (memory ${Memory})")}";
}

// TODO: copy

// TODO: fill

public record Block(string Label) : LabelWasmInstruction(Label) {
  public override byte OpCode => 0x02;

  public override string Wat => $"block ${Label}";
}

public record Branch(string Label) : LabelWasmInstruction(Label) {
  public override byte OpCode => 0x0c;

  public override string Wat => $"br ${Label}";
}

public record BranchIf(string Label) : LabelWasmInstruction(Label) {
  public override byte OpCode => 0x0d;

  public override string Wat => $"br_if ${Label}";
}

public record Call(string FuncName) : WasmInstruction {
  public override byte OpCode => 0x10;
  public override string Wat => $"call ${FuncName}";

  public string FuncName { get; } = FuncName;
}

public record End : WasmInstruction {
  public override byte OpCode => 0x0b;
  public override string Wat => "end";
}

public record If(Else? ElseBranch = null) : WasmInstruction {
  public override byte OpCode => 0x04;
  public override string Wat => "if";

  public Else? ElseBranch { get; } = ElseBranch;
}

public record Else : WasmInstruction {
  public override byte OpCode => 0x05;
  public override string Wat => "else";
}

public record Loop(string Label) : LabelWasmInstruction(Label) {
  public override byte OpCode => 0x03;
  public override string Wat => $"loop ${Label}";
}

public record Return : WasmInstruction {
  public override byte OpCode => 0x0f;
  public override string Wat => "return";
}

public record EmptyType : WasmInstruction {
  public override byte OpCode => 0x40;
  public override string Wat => "nop";
}

public record Comment(string Text) : WasmInstruction {
  public string Text { get; } = Text;
  public override byte OpCode => throw new InvalidOperationException();
  public override string Wat => $";; {Text}";
}
