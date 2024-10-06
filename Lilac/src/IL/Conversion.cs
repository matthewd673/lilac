namespace Lilac.IL;

public abstract record Conversion(Value Value, Type NewType) : Expression {
  public Value Value { get; } = Value;
  public Type NewType { get; } = NewType;
}
