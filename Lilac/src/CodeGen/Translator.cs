using Lilac.Analysis;
using Lilac.CodeGen.Targets.Wasm.Instructions;

namespace Lilac.CodeGen;

public abstract class Translator {
  protected ILTransformer<WasmInstruction> Transformer { get; }
  protected CFGProgram CFGProgram { get; }

  public Translator(ILTransformer<WasmInstruction> transformer,
                    CFGProgram cfgProgram) {
    Transformer = transformer;
    CFGProgram = cfgProgram;
  }

  public abstract Component Translate();
}