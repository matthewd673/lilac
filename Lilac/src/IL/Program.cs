namespace Lilac.IL;

public class Program {
  private Dictionary<string, GlobalDef> globalMap;
  private Dictionary<string, FuncDef> funcMap;
  private Dictionary<(string, string), ExternFuncDef> externFuncMap;

  public int GlobalCount => globalMap.Count;
  public int FuncCount => funcMap.Count;
  public int ExternFuncCount => externFuncMap.Count;

  public Program() {
    globalMap = new();
    funcMap = new();
    externFuncMap = new();
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
    catch (KeyNotFoundException) {
      return null;
    }
  }

  public void AddFunc(FuncDef funcDef) {
    funcMap.Add(funcDef.Name, funcDef);
  }

  public IEnumerable<FuncDef> GetFuncs() {
    foreach (FuncDef f in funcMap.Values) {
      yield return f;
    }
  }

  public FuncDef? GetFunc(string name) {
    try {
      return funcMap[name];
    }
    catch (KeyNotFoundException) {
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
    catch (KeyNotFoundException) {
      return null;
    }
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Program)) {
      return false;
    }

    Program other = (Program)obj;

    if (GlobalCount != other.GlobalCount) {
      return false;
    }

    foreach (string k in globalMap.Keys) {
      if (!globalMap[k].Equals(other.GetGlobal(k))) {
        return false;
      }
    }

    if (FuncCount != other.FuncCount) {
      return false;
    }

    foreach (string k in funcMap.Keys) {
      if (!funcMap[k].Equals(other.GetFunc(k))) {
        return false;
      }
    }

    if (ExternFuncCount != other.ExternFuncCount) {
      return false;
    }

    foreach ((string, string) k in externFuncMap.Keys) {
      if (!externFuncMap[k].Equals(other.GetExternFunc(k.Item1, k.Item2))) {
        return false;
      }
    }

    return true;
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), globalMap, funcMap, externFuncMap);
  }
}
