namespace Lilac.IL;

public class UnaryOp(UnaryOp.Operator op, Value @value) : Expression {
  public enum Operator {
    Neg,
    BoolNot,
    BitNot,
  }

  public Operator Op { get; } = op;
  public Value Value { get; } = @value;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(UnaryOp)) {
      return false;
    }

    UnaryOp other = (UnaryOp)obj;
    return Op.Equals(other.Op) && Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Value);
  }

  public override UnaryOp Clone() => new(Op, Value);

  public override string ToString() => $"(UnaryOp Op={Op} Value={Value})";
}
