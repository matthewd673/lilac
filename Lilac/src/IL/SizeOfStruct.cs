namespace Lilac.IL;

public record SizeOfStruct(string StructName) : SizeOf {
  public string StructName { get; } = StructName;

  public override int GetHashCode() => HashCode.Combine(GetType(), StructName);

  public override string ToString() =>
    $"(SizeOfStruct StructName={StructName})";
}
