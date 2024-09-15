namespace Lilac.IL;

public abstract class Conversion(Value value, Type newType) : Expression {
  public Value Value { get; } = value;
  public Type NewType { get; } = newType;

  public override bool Equals(object? obj) {
    // NOTE: this type equality check is a little less strict than usual
    // so that it doesn't have to be rewritten for every conversion.
    if (obj is null || GetType() != obj.GetType()) {
      return false;
    }

    Conversion other = (Conversion)obj;

    return Value.Equals(other.Value) && NewType.Equals(other.NewType);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value, NewType);
  }
}
