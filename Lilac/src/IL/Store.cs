namespace Lilac.IL;

public class Store(Type type, Value address, Value value) : Statement {
  public Type Type { get; } = type;
  public Value Address { get; } = address;
  public Value Value { get; } = value;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Store)) {
      return false;
    }

    Store other = (Store)obj;
    return Type.Equals(other.Type) && Address.Equals(other.Address) &&
           Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Address, Value);
  }

  public override Store Clone() => new(Type, Address, Value);
}
