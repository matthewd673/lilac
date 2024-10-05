namespace Lilac.IL;

public record Struct(string Name, List<Type> FieldTypes) : Component, INamed {
  public string Name { get; } = Name;
  public List<Type> FieldTypes { get; } = FieldTypes;

  public override int GetHashCode() => HashCode.Combine(GetType(), FieldTypes);

  public override string ToString() =>
    $"(Struct Name={Name} FieldTypes=[{String.Join(", ", FieldTypes)}])";
}
