namespace Lilac.IL;

public record ExternCall(string FuncSource,
                         string FuncName,
                         DeepEqualList<Value> Args) : Call(FuncName, Args) {
  public string FuncSource { get; } = FuncSource;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), FuncSource, FuncName, Args);

  public override string ToString() =>
    $"(ExternCall FuncSource={FuncSource} FuncName={FuncName} " +
    $"Args=[{String.Join(", ", Args)}])";
}
