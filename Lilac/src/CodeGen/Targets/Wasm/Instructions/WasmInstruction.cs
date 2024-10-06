namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public abstract record WasmInstruction : Instruction {
  public abstract byte OpCode { get; }
  public abstract string Wat { get; }
}

public abstract record TypedWasmInstruction(Type Type) : WasmInstruction {
  public Type Type { get; } = Type;
}

public abstract record IntegerTypedWasmInstruction : TypedWasmInstruction {
  public IntegerTypedWasmInstruction(Type Type) : base(Type) {
    if (!Type.IsInteger()) {
      throw new IllegalTypeException(Type, this);
    }
  }
}

public abstract record FloatTypedWasmInstruction : TypedWasmInstruction {
  public FloatTypedWasmInstruction(Type Type) : base(Type) {
    if (!Type.IsFloat()) {
      throw new IllegalTypeException(Type, this);
    }
  }
}

public abstract record VariableWasmInstruction(string Variable)
  : WasmInstruction {
  public string Variable { get; } = Variable;
}

public abstract record LabelWasmInstruction(string label) : WasmInstruction {
  public string Label { get; } = label;
}

public abstract record MemoryWasmInstruction(string? Memory = null)
  : WasmInstruction {
  public string? Memory { get; } = Memory;
}

public abstract record TypedMemoryWasmInstruction(Type Type, string? Memory)
  : WasmInstruction {
  public Type Type { get; } = Type;
  public string? Memory { get; } = Memory;
}

public abstract record IntegerTypedMemoryWasmInstruction
  : TypedMemoryWasmInstruction {
  public IntegerTypedMemoryWasmInstruction(Type Type, string? Memory = null)
    : base(Type, Memory) {
    if (!Type.IsInteger()) {
      throw new IllegalTypeException(Type, this);
    }
  }
}
