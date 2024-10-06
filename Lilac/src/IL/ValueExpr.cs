namespace Lilac.IL;

public record ValueExpr(Value Value) : Expression {
  public Value Value { get; } = Value;

  public override string ToString() => $"(ValueExpr Value={Value})";
}
