using Lilac.IL;
using Lilac.Validation;

namespace Lilac.Tests.ValidationTests;

public class UniqueLabelsTests {
  [Fact]
  public void PassWithEmptyStmtList() {
    UniqueLabels validation = new([]);
    validation.Run();
  }

  [Fact]
  public void PassWithUniqueLabels() {
    List<Statement> stmtList = [
      new Label("L1"),
      new Label("L2"),
      new Label("L3"),
    ];
    UniqueLabels validation = new(stmtList);
    validation.Run();
  }

  [Fact]
  public void FailWithDuplicateLabels() {
    List<Statement> stmtList = [
      new Label("L1"),
      new Label("L2"),
      new Label("L1"),
    ];
    UniqueLabels validation = new(stmtList);
    Assert.Throws<ValidationException>(validation.Run);
  }
}
