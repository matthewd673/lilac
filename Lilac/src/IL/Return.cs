namespace Lilac.IL;

public class Return : Statement {
  public Value Value { get; }

  public Return(Value value) {
    Value = value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Return)) {
      return false;
    }

    Return other = (Return)obj;
    return Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value);
  }

  public override Return Clone() => new(Value);
}
