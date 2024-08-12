namespace Lilac.IL;

public class IntToFloatConversion : Conversion {
  public IntToFloatConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override IntToFloatConversion Clone() => new(Value, NewType);
}
