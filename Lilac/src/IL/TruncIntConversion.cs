namespace Lilac.IL;

public class TruncIntConversion : Conversion {
  public TruncIntConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override TruncIntConversion Clone() => new(Value, NewType);
}
