using Lilac.IL;

namespace Lilac.Analysis;

public class CFGFuncDef(string name,
                        List<FuncParam> @params,
                        IL.Type retType,
                        CFG cfg,
                        bool exported)
  : FuncDef(name, @params, retType, null!, exported) {
  public CFG CFG { get; } = cfg;

  // TODO: implement ToString, Equals, GetHashCode, and Clone

  public override CFGFuncDef Clone() {
    throw new NotImplementedException(); // TODO
  }

  public static CFGFuncDef FromFuncDef(FuncDef funcDef) => new(
    funcDef.Name,
    funcDef.Params,
    funcDef.RetType,
    new CFG(BB.FromStmtList(funcDef.StmtList)),
    funcDef.Exported);
}
