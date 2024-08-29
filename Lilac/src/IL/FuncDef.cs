namespace Lilac.IL;

public class FuncDef(string name,
                     List<FuncParam> @params,
                     Type retType,
                     List<Statement> stmtList,
                     bool exported = false)
  : Component, INamed {
  public string Name { get; } = name;
  public List<FuncParam> Params { get; } = @params;
  public Type RetType { get; } = retType;
  public List<Statement> StmtList { get; } = stmtList;
  public bool Exported { get; } = exported;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(FuncDef)) {
      return false;
    }

    FuncDef other = (FuncDef)obj;

    return Name.Equals(other.Name) && Params.SequenceEqual(other.Params) &&
           RetType.Equals(other.RetType) &&
           StmtList.SequenceEqual(other.StmtList) &&
           Exported.Equals(other.Exported);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name, Params, RetType, StmtList,
                            Exported);
  }

  public override FuncDef Clone() =>
    new(Name, Params, RetType, StmtList, Exported);

  public override string ToString() =>
    $"(FuncDef Name={Name} Params=[{String.Join(", ", Params)}] " +
    $"RetType={RetType} StmtList=[{String.Join(", ", StmtList)}] " +
    $"Exported={Exported})";
}
