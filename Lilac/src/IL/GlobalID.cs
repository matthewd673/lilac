namespace Lilac.IL;

public record GlobalID(string Name) : ID(Name) {
  public override string ToString() => $"(GlobalID Name={Name})";
}
