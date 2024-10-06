namespace Lilac.IL;

public record ExternCall(string FuncSource,
                         string FuncName,
                         DeepEqualList<Value> Args) : Call(FuncName, Args) {
  public string FuncSource { get; } = FuncSource;

  public override string ToString() =>
    $"(ExternCall FuncSource={FuncSource} FuncName={FuncName} " +
    $"Args=[{String.Join(", ", Args)}])";
}
