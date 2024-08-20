namespace Lilac.IL;

public class Label(string name) : Statement {
  public string Name { get; } = name;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Label)) {
      return false;
    }

    Label other = (Label)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override Label Clone() => new(Name);

  public override string ToString() => $"(Label Name={Name})";
}
