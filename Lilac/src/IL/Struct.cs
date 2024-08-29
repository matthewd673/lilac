namespace Lilac.IL;

public class Struct(string name, List<Type> fieldTypes) : Component, INamed {
  public string Name { get; } = name;
  public List<Type> FieldTypes { get; } = fieldTypes;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Struct)) {
      return false;
    }

    Struct other = (Struct)obj;
    return Name.Equals(other.Name) && FieldTypes.SequenceEqual(other.FieldTypes);
  }

  public override int GetHashCode() => HashCode.Combine(GetType(), FieldTypes);

  public override Struct Clone() => new(Name, FieldTypes);

  public override string ToString() =>
    $"(Struct Name={Name} FieldTypes=[{String.Join(", ", FieldTypes)}])";
}
