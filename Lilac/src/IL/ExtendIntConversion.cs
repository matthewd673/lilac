namespace Lilac.IL;

public class ExtendIntConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override ExtendIntConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(ExtendIntConversion Value={Value} NewType={NewType})";
}
