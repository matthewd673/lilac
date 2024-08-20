namespace Lilac.IL;

public class TruncIntConversion(Value value, Type newType)
  : Conversion(value, newType) {
  public override TruncIntConversion Clone() => new(Value, NewType);

  public override string ToString() =>
    $"(TruncIntConversion Value={Value} NewType={NewType})";
}
