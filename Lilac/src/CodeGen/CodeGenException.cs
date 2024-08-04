namespace Lilac.CodeGen;

public class CodeGenException(Instruction instruction, string message)
  : Exception(message) {
  public Instruction Instruction { get; } = instruction;
}