namespace Lilac.IL;

public record Jump(string Target) : Statement {
  public string Target { get; } = Target;

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target);
  }

  public override string ToString() => $"(Jump Target={Target})";
}
