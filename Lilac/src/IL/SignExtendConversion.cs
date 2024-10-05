namespace Lilac.IL;

public record SignExtendConversion(Value Value, Type NewType)
  : Conversion(Value, NewType) {
  public override string ToString() =>
    $"(SignExtendConversion Value={Value} NewType={NewType})";
}
