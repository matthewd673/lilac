using Lilac.Analysis;
using Lilac.IL;

namespace Lilac.CodeGen;

public abstract class ILTransformer<TInstr>(CFGProgram program)
  where TInstr : Instruction {
  protected CFGProgram Program = program;

  public abstract List<TInstr> Transform(Node node);
}