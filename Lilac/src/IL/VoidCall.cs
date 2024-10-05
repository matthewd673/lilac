namespace Lilac.IL;

public record VoidCall(Call Call) : Statement {
  public Call Call { get; } = Call;

  public override int GetHashCode() => HashCode.Combine(GetType(), Call);

  public override string ToString() => $"(VoidCall Call={Call})";
}
