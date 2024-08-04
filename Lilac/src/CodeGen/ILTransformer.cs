namespace Lilac.CodeGen;

public abstract class ILTransformer<TInstr> where TInstr : Instruction {

  public abstract List<TInstr> Transform(IL.Node node);
}