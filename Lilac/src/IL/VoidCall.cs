namespace Lilac.IL;

public class VoidCall(Call call) : Statement {
  public Call Call { get; } = call;

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

  public override string ToString() => $"(VoidCall Call={Call})";
}
