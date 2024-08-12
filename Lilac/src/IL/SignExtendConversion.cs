namespace Lilac.IL;

public class SignExtendConversion : Conversion {
  public SignExtendConversion(Value value, Type newType)
    : base(value, newType) {
    // Empty
  }

  public override SignExtendConversion Clone() => new(Value, NewType);
}
