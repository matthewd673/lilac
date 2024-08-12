using Lilac.Analysis;

namespace Lilac.CodeGen;

public abstract class Translator<TInstr> where TInstr : Instruction {
  protected ILTransformer<TInstr> Transformer { get; set; } = null!;
  protected CFGProgram CFGProgram { get; set; } = null!;

  public Translator(ILTransformer<TInstr> transformer,
                    CFGProgram cfgProgram) {
    Transformer = transformer;
    CFGProgram = cfgProgram;
  }

  // NOTE: for use by Translators that cannot use the default constructor.
  protected Translator() {
    // Empty
  }

  public abstract Component Translate();
}