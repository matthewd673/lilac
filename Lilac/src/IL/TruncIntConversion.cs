namespace Lilac.IL;

public record TruncIntConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(TruncIntConversion Value={Value} NewType={NewType})";
}
