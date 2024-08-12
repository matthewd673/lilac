namespace Lilac.IL;

public class VoidCall : Statement {
  public Call Call { get; }

  public VoidCall(Call call) {
    Call = call;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(VoidCall)) {
      return false;
    }

    VoidCall other = (VoidCall)obj;
    return Call.Equals(other.Call);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Call);
  }

  public override VoidCall Clone() => new(Call);
}
