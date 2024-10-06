namespace Lilac.IL;

public record FuncDef(string Name,
                      DeepEqualList<FuncParam> Params,
                      Type RetType,
                      DeepEqualList<Statement> StmtList,
                      bool Exported = false)
  : Component, INamed {
  public string Name { get; } = Name;
  public DeepEqualList<FuncParam> Params { get; } = Params;
  public Type RetType { get; } = RetType;
  public DeepEqualList<Statement> StmtList { get; } = StmtList;
  public bool Exported { get; } = Exported;

  public override string ToString() =>
    $"(FuncDef Name={Name} Params=[{string.Join(", ", Params)}] " +
    $"RetType={RetType} StmtList=[{string.Join(", ", StmtList)}] " +
    $"Exported={Exported})";
}
