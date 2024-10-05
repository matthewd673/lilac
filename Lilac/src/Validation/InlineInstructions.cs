using Lilac.IL;

namespace Lilac.Validation;

/// <summary>
/// Validate that an InlineInstr Statement has the  expected target and
/// CodeGen Instruction type.
/// </summary>
/// <param name="stmt">The Statement to validate.</param>
/// <param name="target">The expected target name.</param>
/// <param name="instrType">The expected CodeGen Instruction type.</param>
public class InlineInstructions(Statement stmt,
                                string target,
                                System.Type instrType)
  : ValidationPass<Statement> {
  public override string Id => "InlineAssemblyTarget";

  private readonly Statement stmt = stmt;
  private readonly string target = target;
  private readonly System.Type instrType = instrType;

  public override void Run() {
    if (stmt is not InlineInstr inlineInstr) {
      return;
    }

    if (!target.Equals(inlineInstr.Target)) {
      throw new ValidationException(Id, $"Target \"{inlineInstr.Target}\" is not expected target \"{target}\"");
    }

    if (inlineInstr.Instr is null) {
      throw new ValidationException(Id, $"Instruction is null");
    }

    if (!inlineInstr.Instr.GetType().IsSubclassOf(instrType)) {
      throw new ValidationException(Id, $"Instruction of type \"{inlineInstr.Instr.GetType()}\" is not a subclass of expected type \"{instrType}\"");
    }
  }
}
