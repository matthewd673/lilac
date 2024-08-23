namespace Lilac.IL;

public class ExtendFloatConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override ExtendFloatConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(ExtendFloatConversion Value={Value} NewType={NewType})";
}
