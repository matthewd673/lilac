namespace Lilac.IL;

public class Definition(Type type, ID id, Expression rhs) : Statement {
  public Type Type { get; } = type;
  public ID Id { get; } = id;
  public Expression Rhs { get; set; } = rhs;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Definition)) {
      return false;
    }

    Definition other = (Definition)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id) &&
           Rhs.Equals(other.Rhs);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id, Rhs);
  }

  public override Definition Clone() => new(Type, Id, Rhs);

  public override string ToString() =>
    $"(Definition Type={Type} Id={Id} Rhs={Rhs})";
}
