namespace Lilac.IL;

public class ExtendIntConversion : Conversion {
  public ExtendIntConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override ExtendIntConversion Clone() => new(Value, NewType);
}
