namespace Lilac.IL;

public record Label(string Name) : Statement {
  public string Name { get; } = Name;

  public override string ToString() => $"(Label Name={Name})";
}
