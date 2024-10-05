namespace Lilac.IL;

public record FloatToIntConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(FloatToIntConversion Value={Value} NewType={NewType})";
}
