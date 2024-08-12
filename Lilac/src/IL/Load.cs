namespace Lilac.IL;

public class Load(Type type, Value address) : Expression {
  public Type Type { get; } = type;
  public Value Address { get; } = address;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Load)) {
      return false;
    }

    Load other = (Load)obj;
    return Type.Equals(other.Type) && Address.Equals(other.Address);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Address);
  }

  public override Load Clone() => new(Type, Address);
}
