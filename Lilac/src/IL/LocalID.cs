namespace Lilac.IL;

public record LocalID(string Name) : ID(Name) {
  public override string ToString() => $"(LocalID Name={Name})";
}
