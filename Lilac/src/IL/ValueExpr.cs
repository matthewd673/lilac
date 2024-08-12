namespace Lilac.IL;

public class ValueExpr : Expression {
  public Value Value { get; }

  public ValueExpr(Value @value) {
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ValueExpr)) {
      return false;
    }

    ValueExpr other = (ValueExpr)obj;
    return Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value);
  }

  public override ValueExpr Clone() => new(Value);
}
