namespace Lilac.IL;

public record ExtendFloatConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override string ToString() =>
    $"(ExtendFloatConversion Value={Value} NewType={NewType})";
}
