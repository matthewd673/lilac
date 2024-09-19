namespace Lilac.Validation;

using Lilac.IL;

public class InlineInstructions(Program program,
                                string target,
                                System.Type instrType)
  : ValidationPass {
  private readonly Program program = program;
  private readonly string target = target;
  private readonly System.Type instrType = instrType;

  public override string Id => "InlineAssemblyTarget";

  public override void Run() {
    foreach (FuncDef f in program.FuncDefs) {
      ValidateFuncDef(f);
    }
  }

  private void ValidateFuncDef(FuncDef funcDef) {
    foreach (InlineInstr i in funcDef.StmtList.Where(s => s is InlineInstr)) {
      if (!target.Equals(i.Target)) {
        throw new ValidationException(Id, $"Target \"{i.Target}\" is not expected target \"{target}\"");
      }

      if (!i.Instr.GetType().IsSubclassOf(instrType)) {
        throw new ValidationException(Id, $"Instruction of type \"{i.Instr.GetType()}\" is not a subclass of expected type \"{instrType}\"");
      }
    }
  }
}
