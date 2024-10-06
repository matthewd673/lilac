namespace Lilac.IL;

public record Phi(DeepEqualList<ID> Ids) : Expression {
  public DeepEqualList<ID> Ids { get; } = Ids;

  public override int GetHashCode() => HashCode.Combine(GetType(), Ids);

  public override string ToString() => $"(Phi Ids=[{String.Join(", ", Ids)}])";
}
