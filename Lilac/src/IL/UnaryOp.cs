namespace Lilac.IL;

public class UnaryOp : Expression {
  public enum Operator {
    Neg,
    BoolNot,
    BitNot,
  }

  public Operator Op { get; }
  public Value Value { get; }

  public UnaryOp(Operator op, Value @value) {
    Op = op;
    Value = @value;
  }

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
}
