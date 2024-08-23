namespace Lilac.IL;

public class SignTruncConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override SignTruncConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(SignTruncConversion Value={Value} NewType={NewType})";
}
