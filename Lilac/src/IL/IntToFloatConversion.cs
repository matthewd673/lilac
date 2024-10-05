namespace Lilac.IL;

public record IntToFloatConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(IntToFloatConversion Value={Value} NewType={NewType})";
}
