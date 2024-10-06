namespace Lilac.IL;

public record Phi(DeepEqualList<ID> Ids) : Expression {
  public DeepEqualList<ID> Ids { get; } = Ids;

  public override string ToString() => $"(Phi Ids=[{String.Join(", ", Ids)}])";
}
