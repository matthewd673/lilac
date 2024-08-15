namespace Lilac.IL;

public class Constant(Type type, byte[] value) : Value {
  /// <summary>
  /// The type of the Constant.
  /// </summary>
  public Type Type { get; } = type;

  /// <summary>
  /// The value of the Constant represented as an array of bytes. Values are
  /// little-endian. Void type constants may have a zero-length array.
  /// </summary>
  public byte[] Value { get; } = value;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Constant)) {
      return false;
    }

    Constant other = (Constant)obj;
    // Don't check for value equality on void constants, conceptually they don't
    // have a value. This has also been the source of an extremely annoying bug.
    return Type.Equals(other.Type) &&
           (Type.Equals(Type.Void) || Value.SequenceEqual(other.Value));
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Value);
  }

  public override Constant Clone() => new(Type, Value);
}
