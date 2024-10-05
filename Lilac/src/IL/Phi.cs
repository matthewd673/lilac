namespace Lilac.IL;

public record Phi(List<ID> Ids) : Expression {
  public List<ID> Ids { get; } = Ids;

  public override int GetHashCode() => HashCode.Combine(GetType(), Ids);

  public override string ToString() => $"(Phi Ids=[{String.Join(", ", Ids)}])";
}
