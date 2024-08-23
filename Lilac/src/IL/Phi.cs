namespace Lilac.IL;

public class Phi : Expression {
  public List<ID> Ids { get; }

  public Phi(List<ID> ids) {
    Ids = ids;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Phi)) {
      return false;
    }

    Phi other = (Phi)obj;
    return Ids.SequenceEqual(other.Ids);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Ids);
  }

  public override Phi Clone() => new(Ids);

  public override string ToString() => $"(Phi Ids=[{String.Join(", ", Ids)}])";
}
