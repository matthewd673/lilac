namespace Lilac.IL;

public class FloatToIntConversion : Conversion {
  public FloatToIntConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override FloatToIntConversion Clone() => new(Value, NewType);
}
