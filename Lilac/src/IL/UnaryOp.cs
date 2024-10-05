namespace Lilac.IL;

public record UnaryOp(UnaryOp.Operator Op, Value Value) : Expression {
  public enum Operator {
    Neg,
    BoolNot,
    BitNot,
  }

  public Operator Op { get; } = Op;
  public Value Value { get; } = Value;

  public override int GetHashCode() => HashCode.Combine(GetType(), Op, Value);

  public override string ToString() => $"(UnaryOp Op={Op} Value={Value})";
}
