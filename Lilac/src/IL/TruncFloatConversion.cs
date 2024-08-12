namespace Lilac.IL;

public class TruncFloatConversion : Conversion {
  public TruncFloatConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override TruncFloatConversion Clone() => new(Value, NewType);
}
