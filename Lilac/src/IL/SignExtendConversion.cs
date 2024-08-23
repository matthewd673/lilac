namespace Lilac.IL;

public class SignExtendConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override SignExtendConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(SignExtendConversion Value={Value} NewType={NewType})";
}
