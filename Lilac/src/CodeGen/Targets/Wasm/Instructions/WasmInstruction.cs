namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public abstract class WasmInstruction : Instruction {
  public abstract byte OpCode { get; }
  public abstract string Wat { get; }

  public override bool Equals(object? obj) {
    if (obj is not WasmInstruction other) {
      return false;
    }

    return OpCode.Equals(other.OpCode);
  }

  public override int GetHashCode() {
    return OpCode.GetHashCode();
  }
}

public abstract class TypedWasmInstruction(Type type) : WasmInstruction {
  public Type Type { get; } = type;

  public override bool Equals(object? obj) {
    if (obj is not TypedWasmInstruction other) {
      return false;
    }

    return OpCode.Equals(other.OpCode) && Type.Equals(other.Type);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Type);
  }
}

public abstract class VariableWasmInstruction(string variable)
  : WasmInstruction {
  public string Variable { get; } = variable;

  public override bool Equals(object? obj) {
    if (obj is not VariableWasmInstruction other) {
      return false;
    }

    return OpCode.Equals(other.OpCode) && Variable.Equals(other.Variable);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Variable);
  }
}

public abstract class LabelWasmInstruction(string label) : WasmInstruction {
  public string Label { get; } = label;

  public override bool Equals(object? obj) {
    if (obj is not LabelWasmInstruction other) {
      return false;
    }

    return OpCode.Equals(other.OpCode) && Label.Equals(other.Label);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Label);
  }
}

public abstract class MemoryWasmInstruction(string memory = "")
  : WasmInstruction {
  public string Memory { get; } = memory;

  public override bool Equals(object? obj) {
    if (obj is not MemoryWasmInstruction other) {
      return false;
    }

    return OpCode.Equals(other.OpCode) && Memory.Equals(other.Memory);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Memory);
  }
}

public abstract class TypedMemoryWasmInstruction(Type type, string memory = "")
  : WasmInstruction {
  public Type Type { get; } = type;
  public string Memory { get; } = memory;

  public override bool Equals(object? obj) {
    if (obj is not TypedMemoryWasmInstruction other) {
      return false;
    }

    return Type.Equals(other.Type) && Memory.Equals(other.Memory);
  }

  public override int GetHashCode() {
    return HashCode.Combine(OpCode, Type, Memory);
  }
}