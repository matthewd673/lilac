using Lilac.IL;
using Lilac.Validation;
using Instructions = Lilac.CodeGen.Targets.Wasm.Instructions;

namespace Lilac.Tests.ValidationTests;

public class InlineInstructionsTests {
  [Fact]
  public void PassWhenNotInlineInstr() {
    InlineInstructions validation = new(new Label("target"), "wasm",
      typeof(Instructions.WasmInstruction));
    validation.Run();
  }

  [Fact]
  public void PassWithValidInlineInstr() {
    InlineInstr i = new("wasm",
        new Instructions.Const(Instructions.Type.I32, "0"));
    InlineInstructions validation = new(i, "wasm",
      typeof(Instructions.WasmInstruction));
    validation.Run();
  }

  [Fact]
  public void FailWithTargetMismatch() {
    InlineInstr i = new("different target",
        new Instructions.Const(Instructions.Type.I32, "0"));
    InlineInstructions validation = new(i, "wasm",
      typeof(Instructions.WasmInstruction));
    Assert.Throws<ValidationException>(validation.Run);
  }

  [Fact]
  public void FailWithNullInstr() {
    InlineInstr i = new("wasm", null);
    InlineInstructions validation = new(i, "wasm",
      typeof(Instructions.WasmInstruction));
    Assert.Throws<ValidationException>(validation.Run);
  }

  // TODO: FailWithInstrTypeMismatch
  //  (there is only one target with instructions implemented right now)
}
