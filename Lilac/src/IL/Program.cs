namespace Lilac.IL;

public class Program : Program<FuncDef> {
  // This is the "default" Program class.
}

public class Program<TFuncDef> where TFuncDef : FuncDef {
  public NamedCollection<GlobalDef> Globals { get; } = new();
  public NamedCollection<TFuncDef> FuncDefs { get; } = new();
  public NamedCollection<ExternFuncDef, (string, string)> ExternFuncDefs = new();
  public NamedCollection<Struct> Structs = new();

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
