namespace Lilac.IL;

public class Definition : Statement {
  public Type Type { get; }
  public ID Id { get; }
  public Expression Rhs { get; set; }

  public Definition(Type type, ID id, Expression rhs) {
    Type = type;
    Id = id;
    Rhs = rhs;
  }

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
}
