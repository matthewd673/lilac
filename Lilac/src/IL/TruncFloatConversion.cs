namespace Lilac.IL;

public record TruncFloatConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override string ToString() =>
    $"(TruncFloatConversion Value={Value} NewType={NewType})";
}
