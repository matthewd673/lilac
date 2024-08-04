namespace Lilac.CodeGen.Targets.Wasm.Instructions;

public class IllegalTypeException(Type type, WasmInstruction instruction)
  : CodeGenException(instruction,
      $"Illegal type \"{type}\" in instruction \"{instruction.Wat}\"") {
  public Type Type { get; } = type;
}