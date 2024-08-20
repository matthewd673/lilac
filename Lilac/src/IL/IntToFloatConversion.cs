namespace Lilac.IL;

public class IntToFloatConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override IntToFloatConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(IntToFloatConversion Value={Value} NewType={NewType})";
}
