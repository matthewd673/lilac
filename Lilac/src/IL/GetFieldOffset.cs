namespace Lilac.IL;

public class GetFieldOffset(Value address, string structName, int index)
  : Expression {
  public Value Address { get; } = address;
  public string StructName { get; } = structName;
  public int Index { get; } = index;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(GetFieldOffset)) {
      return false;
    }

    GetFieldOffset other = (GetFieldOffset)obj;
    return Address.Equals(other.Address) &&
           StructName.Equals(other.StructName) &&
           Index.Equals(other.Index);
  }

  public override int GetHashCode() => HashCode.Combine(GetType(), Index);

  public override GetFieldOffset Clone() => new(Address, StructName, Index);

  public override string ToString() =>
    $"(GetFieldOffset Address={Address} StructName={StructName} Index={Index})";
}