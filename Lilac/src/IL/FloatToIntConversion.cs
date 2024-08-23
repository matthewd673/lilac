namespace Lilac.IL;

public class FloatToIntConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override FloatToIntConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(FloatToIntConversion Value={Value} NewType={NewType})";
}
