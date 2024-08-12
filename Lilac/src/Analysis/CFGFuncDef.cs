using Lilac.IL;

namespace Lilac.Analysis;

public class CFGFuncDef : Component {
  public string Name { get; }
  public List<FuncParam> Params { get; }
  public IL.Type RetType { get; }
  public CFG CFG { get; }
  public bool Exported { get; }

  public CFGFuncDef(string name,
                    List<FuncParam> @params,
                    IL.Type retType,
                    CFG cfg,
                    bool exported) {
    Name = name;
    Params = @params;
    RetType = retType;
    CFG = cfg;
    Exported = exported;
  }

  // TODO: implement ToString, Equals, GetHashCode, and Clone

  public override CFGFuncDef Clone() {
    // TODO
    throw new NotImplementedException();
  }
}
