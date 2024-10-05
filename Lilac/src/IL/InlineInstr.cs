namespace Lilac.IL;

public record InlineInstr(string Target, CodeGen.Instruction Instr) : Statement {
  public string Target { get; } = Target;
  public CodeGen.Instruction Instr { get; } = Instr;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), Target, Instr);

  public override string ToString() =>
    $"(InlineInstr Target={Target} Instr={Instr})";
}
