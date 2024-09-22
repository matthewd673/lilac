using Lilac.IL;

namespace Lilac.Validation;

/// <summary>
/// Validate that all InlineInstr Statements in a Program have the expected
/// target and CodeGen Instruction type.
/// </summary>
/// <param name="program">The Program to validate.</param>
/// <param name="target">The expected target name.</param>
/// <param name="instrType">The expected CodeGen Instruction type.</param>
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
