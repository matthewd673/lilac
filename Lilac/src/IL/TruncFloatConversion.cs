namespace Lilac.IL;

public class TruncFloatConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override TruncFloatConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(TruncFloatConversion Value={Value} NewType={NewType})";
}
