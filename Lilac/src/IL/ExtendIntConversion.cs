namespace Lilac.IL;

public record ExtendIntConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override string ToString() =>
    $"(ExtendIntConversion Value={Value} NewType={NewType})";
}
