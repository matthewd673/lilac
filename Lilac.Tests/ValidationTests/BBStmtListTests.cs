using Lilac.Analysis;
using Lilac.IL;
using Lilac.IL.Math;
using Lilac.Validation;

namespace Lilac.Tests.ValidationTests;

public class BBStmtListTests {
  [Fact]
  public void PassWithEmptyStmtList() {
    BB bb = new("", new Label("entry"), null, []);
    BBStmtList validation = new(bb);
    validation.Run();
  }

  [Fact]
  public void PassWithValidStmtList() {
    List<Statement> stmtList = [
      new Return(new Constant(IL.Type.I32, InternalMath.GetZero(IL.Type.I32)))
    ];
    BB bb = new("", new Label("entry"), null, stmtList);
    BBStmtList validation = new(bb);
    validation.Run();
  }

  [Fact]
  public void FailWithJump() {
    List<Statement> stmtList = [
      new Jump("target"),
    ];
    BB bb = new("", new Label("entry"), null, stmtList);
    BBStmtList validation = new(bb);
    Assert.Throws<ValidationException>(validation.Run);
  }

  [Fact]
  public void FailWithCondJump() {
    List<Statement> stmtList = [
      new JumpNotZero("target",
                      new Constant(IL.Type.I32,
                                   InternalMath.GetZero(IL.Type.I32))),
    ];
    BB bb = new("", new Label("entry"), null, stmtList);
    BBStmtList validation = new(bb);
    Assert.Throws<ValidationException>(validation.Run);
  }

  [Fact]
  public void FailWithLabel() {
    List<Statement> stmtList = [
      new Label("label"),
    ];
    BB bb = new("", new Label("entry"), null, stmtList);
    BBStmtList validation = new(bb);
    Assert.Throws<ValidationException>(validation.Run);
  }
}
