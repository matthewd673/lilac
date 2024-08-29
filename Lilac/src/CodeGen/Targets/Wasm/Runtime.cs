using Lilac.CodeGen.Targets.Wasm.Instructions;
using Type = Lilac.IL.Type;

namespace Lilac.CodeGen.Targets.Wasm;

internal static class Runtime {
  // NOTE: Wasm is 32-bit.
  // TODO: consider storing this another way, perhaps in IL?
  public const Instructions.Type PointerType = Instructions.Type.I32;

  public const int StackSizePages = 1;
  public const string StackPointerName = "@__lilac_sp";
  public const string LocalStackMarkerName = "@__lilac_sm";

  public static readonly List<WasmComponent> StackEmulatorComponents = [
    new Memory(StackSizePages),
    new Global(PointerType,
               StackPointerName,
               new(PointerType, "0"),
               true),
  ];

  public static readonly List<WasmComponent> FuncStackEmulatorComponents = [
    new Local(PointerType, LocalStackMarkerName),
  ];

  public static readonly List<WasmInstruction> FuncStartStackEmulatorInstrs = [
    new GlobalGet(StackPointerName),
    new LocalSet(LocalStackMarkerName),
  ];

  public static readonly List<WasmInstruction> FuncEndStackEmulatorInstrs = [
    new LocalGet(LocalStackMarkerName),
    new GlobalSet(StackPointerName),
  ];
}
