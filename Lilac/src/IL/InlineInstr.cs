namespace Lilac.IL;

public class InlineInstr : Statement {
  public string Target { get; }
  public CodeGen.Instruction Instr { get; }

  public InlineInstr(string target, CodeGen.Instruction instr) {
    Target = target;
    Instr = instr;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(InlineInstr)) {
      return false;
    }

    InlineInstr other = (InlineInstr)obj;
    return Target.Equals(other.Target) && Instr.Equals(other.Instr);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target, Instr);
  }

  public override InlineInstr Clone() => new(Target, Instr);
}
