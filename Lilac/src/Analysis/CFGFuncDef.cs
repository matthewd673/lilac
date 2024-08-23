using Lilac.IL;

namespace Lilac.Analysis;

public class CFGFuncDef(string name,
                        List<FuncParam> @params,
                        IL.Type retType,
                        CFG cfg,
                        bool exported)
  : FuncDef(name, @params, retType, null!, exported) {
  public string Name { get; } = name;
  public List<FuncParam> Params { get; } = @params;
  public IL.Type RetType { get; } = retType;
  public CFG CFG { get; } = cfg;
  public bool Exported { get; } = exported;

  // TODO: implement ToString, Equals, GetHashCode, and Clone

  public override CFGFuncDef Clone() {
    // TODO
    throw new NotImplementedException();
  }
}
