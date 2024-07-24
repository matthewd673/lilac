using Lilac.Analysis;

namespace Lilac.CodeGen;

public abstract class Translator {
  protected ILTransformer Transformer { get; }
  protected CFGProgram CFGProgram { get; }

  public Translator(ILTransformer transformer, CFGProgram cfgProgram) {
    Transformer = transformer;
    CFGProgram = cfgProgram;
  }

  public abstract Component Translate();
}