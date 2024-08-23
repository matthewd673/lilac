namespace Lilac.IL;

public class Call : Expression {
  public string FuncName { get; }
  public List<Value> Args { get; }

  public Call(string funcName, List<Value> args) {
    FuncName = funcName;
    Args = args;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Call)) {
      return false;
    }

    Call other = (Call)obj;
    return FuncName.Equals(other.FuncName) && Args.SequenceEqual(other.Args);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncName, Args);
  }

  public override Call Clone() => new(FuncName, Args);

  public override string ToString() =>
    $"(Call FuncName={FuncName} Args=[{String.Join(", ", Args)}])";
}
