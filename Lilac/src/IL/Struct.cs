namespace Lilac.IL;

public class Struct(List<Type> fields) : Component {
  public List<Type> Fields { get; } = fields;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Struct)) {
      return false;
    }

    Struct other = (Struct)obj;
    return Fields.SequenceEqual(other.Fields);
  }

  public override int GetHashCode() => HashCode.Combine(GetType(), Fields);

  public override Struct Clone() => new(Fields);
}