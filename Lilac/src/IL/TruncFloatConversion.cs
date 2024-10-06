namespace Lilac.IL;

public record TruncFloatConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(TruncFloatConversion Value={Value} NewType={NewType})";
}
