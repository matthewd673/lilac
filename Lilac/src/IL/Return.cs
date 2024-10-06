namespace Lilac.IL;

public record Return(Value Value) : Statement {
  public Value Value { get; } = Value;

  public override string ToString() => $"(Return Value={Value})";
}
