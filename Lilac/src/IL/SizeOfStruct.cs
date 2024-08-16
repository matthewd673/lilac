namespace Lilac.IL;

public class SizeOfStruct(string structName) : SizeOf {
  public string StructName { get; } = structName;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(SizeOfStruct)) {
      return false;
    }

    SizeOfStruct other = (SizeOfStruct)obj;
    return StructName.Equals(other.StructName);
  }

  public override int GetHashCode() => HashCode.Combine(GetType(), StructName);

  public override SizeOfStruct Clone() => new(StructName);
}