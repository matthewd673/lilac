namespace Lilac.IL;

public class ExternCall(string funcSource, string funcName, List<Value> args)
  : Call(funcName, args) {
  public string FuncSource { get; } = funcSource;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ExternCall)) {
      return false;
    }

    ExternCall other = (ExternCall)obj;
    return FuncSource.Equals(other.FuncSource) &&
           FuncName.Equals(other.FuncName) &&
           Args.SequenceEqual(other.Args);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncSource, FuncName, Args);
  }

  public override ExternCall Clone() => new(FuncSource, FuncName, Args);

  public override string ToString() =>
    $"(ExternCall FuncSource={FuncSource} FuncName={FuncName} " +
    $"Args=[{String.Join(", ", Args)}])";
}
