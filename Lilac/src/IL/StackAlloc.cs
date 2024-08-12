namespace Lilac.IL;

public class StackAlloc(Type type) : Expression {
  public Type Type { get; } = type;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(StackAlloc)) {
      return false;
    }

    StackAlloc other = (StackAlloc)obj;
    return Type.Equals(other.Type);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type);
  }

  public override StackAlloc Clone() => new(Type);
}
