namespace Lilac.IL;

public class Program : Program<FuncDef> {
  // This is the "default" Program class.
}

public class Program<TFuncDef> where TFuncDef : FuncDef {
  public NamedCollection<GlobalDef> Globals { get; } = [];
  public NamedCollection<TFuncDef> FuncDefs { get; } = [];
  public NamedCollection<ExternFuncDef, (string, string)> ExternFuncDefs = [];
  public NamedCollection<Struct> Structs = [];

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Program)) {
      return false;
    }

    Program other = (Program)obj;

    return Globals.Equals(other.Globals) &&
      FuncDefs.Equals(other.FuncDefs) &&
      ExternFuncDefs.Equals(other.ExternFuncDefs) &&
      Structs.Equals(other.Structs);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(),
                            Globals,
                            FuncDefs,
                            ExternFuncDefs,
                            Structs);
  }
}
