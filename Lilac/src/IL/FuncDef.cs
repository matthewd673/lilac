namespace Lilac.IL;

public record FuncDef(string Name,
                      List<FuncParam> Params,
                      Type RetType,
                      List<Statement> StmtList,
                      bool Exported = false)
  : Component, INamed {
  public string Name { get; } = Name;
  public List<FuncParam> Params { get; } = Params;
  public Type RetType { get; } = RetType;
  public List<Statement> StmtList { get; } = StmtList;
  public bool Exported { get; } = Exported;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), Name, Params, RetType, StmtList, Exported);

  public override string ToString() =>
    $"(FuncDef Name={Name} Params=[{string.Join(", ", Params)}] " +
    $"RetType={RetType} StmtList=[{string.Join(", ", StmtList)}] " +
    $"Exported={Exported})";
}
