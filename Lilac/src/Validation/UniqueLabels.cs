using Lilac.IL;

namespace Lilac.Validation;

/// <summary>
/// Validate that all Labels within a Statement list have unique names.
/// </summary>
/// <param name="stmtList">The Statement list to validate.</param>
public class UniqueLabels(List<Statement> stmtList)
  : ValidationPass<List<Statement>> {
  public override string Id => "UniqueLabels";

  private readonly List<Statement> stmtList = stmtList;

  public override void Run() {
    HashSet<string> names = [];
    foreach (Label l in stmtList.Where(s => s is Label)) {
      if (!names.Add(l.Name)) {
        throw new ValidationException(Id, $"Label name \"{l.Name}\" is not unique in Statement list");
      }
    }
  }
}
