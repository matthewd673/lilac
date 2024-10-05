namespace Lilac.IL;

public record GlobalID(string Name) : ID(Name) {
  public override int GetHashCode() => HashCode.Combine(GetType(), Name);

  public override string ToString() => $"(GlobalID Name={Name})";
}
