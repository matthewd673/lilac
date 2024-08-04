using Lilac.Analysis;

namespace Lilac.CodeGen;

public abstract class Translator<TInstr> where TInstr : Instruction {
  protected ILTransformer<TInstr> Transformer { get; set; }
  protected CFGProgram CFGProgram { get; set; }

  public Translator(ILTransformer<TInstr> transformer,
                    CFGProgram cfgProgram) {
    Transformer = transformer;
    CFGProgram = cfgProgram;
  }

  // NOTE: for use by Translators that cannot use the default constructor.
  protected Translator() {
    throw new NotImplementedException();
  }

  public abstract Component Translate();
}