namespace Lilac.IL;

public record Label(string Name) : Statement {
  public string Name { get; } = Name;

  public override int GetHashCode() => HashCode.Combine(GetType(), Name);

  public override string ToString() => $"(Label Name={Name})";
}
