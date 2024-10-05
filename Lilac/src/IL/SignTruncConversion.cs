namespace Lilac.IL;

public record SignTruncConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(SignTruncConversion Value={Value} NewType={NewType})";
}
