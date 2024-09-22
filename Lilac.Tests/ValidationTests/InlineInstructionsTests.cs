using Lilac.IL;
using Lilac.Validation;
using Instructions = Lilac.CodeGen.Targets.Wasm.Instructions;

namespace Lilac.Tests.ValidationTests;

public class InlineInstructionsTests {
  [Fact]
  public void PassWithEmptyList() {
    InlineInstructions validation = new([], "wasm",
      typeof(Instructions.WasmInstruction));
    validation.Run();
  }

  [Fact]
  public void PassWithNoInlineInstrs() {
    List<Statement> stmtList = [
      new Label("target"),
      new Jump("target"),
    ];
    InlineInstructions validation = new(stmtList, "wasm",
      typeof(Instructions.WasmInstruction));
    validation.Run();
  }

  [Fact]
  public void PassWithValidInlineInstr() {
    List<Statement> stmtList = [
      new InlineInstr("wasm",
        new Instructions.Const(Instructions.Type.I32, "0")),
    ];
    InlineInstructions validation = new(stmtList, "wasm",
      typeof(Instructions.WasmInstruction));
    validation.Run();
  }

  [Fact]
  public void FailWithTargetMismatch() {
    List<Statement> stmtList = [
      new InlineInstr("different target",
        new Instructions.Const(Instructions.Type.I32, "0")),
    ];
    InlineInstructions validation = new(stmtList, "wasm",
      typeof(Instructions.WasmInstruction));
    Assert.Throws<ValidationException>(validation.Run);
  }

  [Fact]
  public void FailWithNullInstr() {
    List<Statement> stmtList = [
      new InlineInstr("wasm", null),
    ];
    InlineInstructions validation = new(stmtList, "wasm",
      typeof(Instructions.WasmInstruction));
    Assert.Throws<ValidationException>(validation.Run);
  }

  // TODO: FailWithInstrTypeMismatch
  //  (there is only one target with instructions implemented right now)
}
