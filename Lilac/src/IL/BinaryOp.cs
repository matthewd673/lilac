namespace Lilac.IL;

public class BinaryOp : Expression {
  public enum Operator {
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Eq,
    Neq,
    Lt,
    Gt,
    Leq,
    Geq,
    BoolAnd,
    BoolOr,
    BitLs,
    BitRs,
    BitAnd,
    BitOr,
    BitXor,
  }

  public Operator Op { get; }
  public Value Left { get; }
  public Value Right { get; }

  public BinaryOp(Operator op, Value left, Value right) {
    Op = op;
    Left = left;
    Right = right;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(BinaryOp)) {
      return false;
    }

    BinaryOp other = (BinaryOp)obj;
    return Op.Equals(other.Op) && Left.Equals(other.Left) &&
           Right.Equals(other.Right);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Left, Right);
  }

  public override BinaryOp Clone() => new(Op, Left, Right);
}
