namespace Lilac.IL;

public record Call(string FuncName, DeepEqualList<Value> Args) : Expression {
  public string FuncName { get; } = FuncName;
  public DeepEqualList<Value> Args { get; } = Args;

  public override string ToString() =>
    $"(Call FuncName={FuncName} Args=[{string.Join(", ", Args)}])";
}
