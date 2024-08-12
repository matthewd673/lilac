namespace Lilac.IL;

public class ExternCall : Call {
  public string FuncSource { get; }

  public ExternCall(string funcSource,
                    string funcName,
                    List<Value> args)
    : base(funcName, args) {
    FuncSource = funcSource;
  }

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
}
