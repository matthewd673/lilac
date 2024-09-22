using Lilac.Analysis;
using Lilac.IL;

namespace Lilac.Validation;

/// <summary>
/// Validate that a BB's Statement list does not contain any illegal Statements
/// (e.g.: Label, Jump).
/// </summary>
/// <param name="bb">The BB to validate.</param>
public class BBStmtList(BB bb) : ValidationPass {
  private readonly BB bb = bb;

  public override string Id => "BBStmtList";

  public override void Run() {
    if (bb.StmtList.Where(s => s is Label or Jump).Any()) {
      throw new ValidationException(Id, "BB statement list contains Jump or Label Statements.");
    }
  }
}
