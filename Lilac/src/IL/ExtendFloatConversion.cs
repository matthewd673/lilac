namespace Lilac.IL;

public class ExtendFloatConversion : Conversion {
  public ExtendFloatConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override ExtendFloatConversion Clone() => new(Value, NewType);
}
