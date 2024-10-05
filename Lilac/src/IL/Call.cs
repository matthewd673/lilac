namespace Lilac.IL;

public record Call(string FuncName, List<Value> Args) : Expression {
  public string FuncName { get; } = FuncName;
  public List<Value> Args { get; } = Args;

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncName, Args);
  }

  public override string ToString() =>
    $"(Call FuncName={FuncName} Args=[{String.Join(", ", Args)}])";
}
