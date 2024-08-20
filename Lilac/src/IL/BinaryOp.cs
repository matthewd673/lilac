namespace Lilac.IL;

public class BinaryOp : Expression {
  public enum Operator {
    /// <summary>
    /// Addition
    /// </summary>
    Add,
    /// <summary>
    /// Subtraction
    /// </summary>
    Sub,
    /// <summary>
    /// Multiplication
    /// </summary>
    Mul,
    /// <summary>
    /// Division. If the operands are integers then integer division.
    /// </summary>
    Div,
    /// <summary>
    /// Modulo. Behavior is undefined if operands are floats.
    /// </summary>
    Mod,
    /// <summary>
    /// Equals
    /// </summary>
    Eq,
    /// <summary>
    /// Not equals
    /// </summary>
    Neq,
    /// <summary>
    /// Less than
    /// </summary>
    Lt,
    /// <summary>
    /// Greater than
    /// </summary>
    Gt,
    /// <summary>
    /// Less than or equals
    /// </summary>
    Leq,
    /// <summary>
    /// Greater than or equals
    /// </summary>
    Geq,
    /// <summary>
    /// Boolean AND. Behavior is undefined if operands are floats.
    /// </summary>
    BoolAnd,
    /// <summary>
    /// Boolean OR. Behavior is undefined if operands are floats.
    /// </summary>
    BoolOr,
    /// <summary>
    /// Bitwise left shift
    /// </summary>
    BitLs,
    /// <summary>
    /// Bitwise arithmetic right shift
    /// </summary>
    BitRs,
    /// <summary>
    /// Bitwise AND
    /// </summary>
    BitAnd,
    /// <summary>
    /// Bitwise OR
    /// </summary>
    BitOr,
    /// <summary>
    /// Bitwise XOR
    /// </summary>
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

  public override string ToString() =>
    $"(BinaryOp Op={Op} Left={Left} Right={Right})";
}
