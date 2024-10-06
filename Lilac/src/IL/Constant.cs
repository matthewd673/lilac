using Lilac.IL.Math;

namespace Lilac.IL;

public record Constant(Type Type, DeepEqualArray<byte> Value) : Value {
  /// <summary>
  /// The type of the Constant.
  /// </summary>
  public Type Type { get; } = Type;

  /// <summary>
  /// The value of the Constant represented as an array of bytes. Values are
  /// little-endian. Void type constants may have a zero-length array.
  /// </summary>
  public DeepEqualArray<byte> Value { get; } = Value;

  /// <summary>
  /// Construct a new Constant from a C# numeric value (e.g.: <c>int</c>).
  /// </summary>
  /// <param name="type">The type of the Constant.</param>
  /// <param name="numericValue">
  ///   The numeric value, which will be encoded into a byte array.
  /// </param>
  public Constant(Type Type, object NumericValue)
    : this(Type, new DeepEqualArray<byte>(ValueEncoder.Encode(Type, NumericValue))) {
    // Empty
  }

  public Constant(Type Type, byte[] Value)
    : this(Type, new DeepEqualArray<byte>(Value)) {
    // Empty
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Value);
  }

  public override string ToString() =>
    $"(Constant Type={Type} Value=[{string.Join(", ", Value)}])";
}
