namespace Lilac.IL;

public class FuncDef : Component {
  public string Name { get; }
  public List<FuncParam> Params { get; }
  public Type RetType { get; }
  public List<Statement> StmtList { get; }
  public bool Exported { get; }

  public FuncDef(string name,
                 List<FuncParam> @params,
                 Type retType,
                 List<Statement> stmtList,
                 bool exported = false) {
    Name = name;
    Params = @params;
    RetType = retType;
    StmtList = stmtList;
    Exported = exported;
  }

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
}
