namespace Lilac.IL;

public class SignTruncConversion : Conversion {
  public SignTruncConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override SignTruncConversion Clone() => new(Value, NewType);
}
