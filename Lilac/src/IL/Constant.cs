namespace Lilac.IL;

public class Constant : Value {
  public Type Type { get; }
  public object Value { get; }

  public Constant(Type type, object @value) {
    Type = type;
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Constant)) {
      return false;
    }

    Constant other = (Constant)obj;
    // Don't check for value equality on void constants, conceptually they don't
    // have a value. This has also been the source of an extremely annoying bug.
    return Type.Equals(other.Type) &&
           (Type.Equals(Type.Void) || Value.Equals(other.Value));
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Value);
  }

  public override Constant Clone() => new(Type, Value);
}
