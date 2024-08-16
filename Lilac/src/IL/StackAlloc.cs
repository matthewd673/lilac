namespace Lilac.IL;

public class StackAlloc(SizeOf size) : Expression {
  public SizeOf Size { get; } = size;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(StackAlloc)) {
      return false;
    }

    StackAlloc other = (StackAlloc)obj;
    return Size.Equals(other.Size);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Size);
  }

  public override StackAlloc Clone() => new(Size);
}
