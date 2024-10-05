using Lilac.IL;

namespace Lilac.Analysis;

public record CFGFuncDef(string Name,
                        List<FuncParam> Params,
                        IL.Type RetType,
                        CFG Cfg,
                        bool Exported)
  : FuncDef(Name, Params, RetType, null!, Exported) {
  public CFG CFG { get; } = Cfg;

  // TODO: implement ToString and GetHashCode

  public static CFGFuncDef FromFuncDef(FuncDef funcDef) => new(
    funcDef.Name,
    funcDef.Params,
    funcDef.RetType,
    new CFG(BB.FromStmtList(funcDef.StmtList)),
    funcDef.Exported);
}
