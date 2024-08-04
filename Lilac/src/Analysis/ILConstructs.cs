using Lilac.IL;

namespace Lilac.Analysis;

public class CFGFuncDef {
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
}

public class CFGProgram {
  private Dictionary<string, GlobalDef> globalMap;
  private Dictionary<string, CFGFuncDef> funcMap;
  private Dictionary<(string, string), ExternFuncDef> externFuncMap;

  public CFGProgram() {
    globalMap = new();
    funcMap = new();
    externFuncMap = new();
  }

  public static CFGProgram FromProgram(Program program) {
    // create CFGProgram from main
    CFGProgram cfgProgram = new();

    // add all global definitions
    foreach (GlobalDef g in program.GetGlobals()) {
      cfgProgram.AddGlobal(g);
    }

    // convert all functions to cfg and add them
    foreach (FuncDef f in program.GetFuncs()) {
      List<BB> funcBlocks = BB.FromStmtList(f.StmtList);
      CFG funcCfg = new CFG(funcBlocks);
      CFGFuncDef cfgFuncDef = new CFGFuncDef(f.Name,
                                             f.Params,
                                             f.RetType,
                                             funcCfg,
                                             f.Exported);

      cfgProgram.AddFunc(cfgFuncDef);
    }

    // add all extern functions (which have no body so don't need conversion)
    foreach (ExternFuncDef f in program.GetExternFuncs()) {
      cfgProgram.AddExternFunc(f);
    }

    return cfgProgram;
  }

  public void AddGlobal(GlobalDef globalDef) {
    globalMap.Add(globalDef.Id.Name, globalDef);
  }

  public IEnumerable<GlobalDef> GetGlobals() {
    foreach (GlobalDef g in globalMap.Values) {
      yield return g;
    }
  }

  public GlobalDef? GetGlobal(string name) {
    try {
      return globalMap[name];
    }
    catch (KeyNotFoundException e) {
      return null;
    }
  }

  public void AddFunc(CFGFuncDef funcDef) {
    funcMap.Add(funcDef.Name, funcDef);
  }

  public IEnumerable<CFGFuncDef> GetFuncs() {
    foreach (CFGFuncDef f in funcMap.Values) {
      yield return f;
    }
  }

  public CFGFuncDef? GetFunc(string name) {
    try {
      return funcMap[name];
    }
    catch (KeyNotFoundException e) {
      return null;
    }
  }

  public void AddExternFunc(ExternFuncDef externFuncDef) {
    externFuncMap.Add((externFuncDef.Source, externFuncDef.Name),
                      externFuncDef);
  }

  public IEnumerable<ExternFuncDef> GetExternFuncs() {
    foreach (ExternFuncDef f in externFuncMap.Values) {
      yield return f;
    }
  }

  public ExternFuncDef? GetExternFunc(string source, string name) {
    try {
      return externFuncMap[(source, name)];
    }
    catch (KeyNotFoundException e) {
      return null;
    }
  }

  // TODO: implement ToString, Equals, GetHashCode, and Clone
}
