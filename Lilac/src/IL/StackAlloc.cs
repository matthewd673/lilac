namespace Lilac.IL;

public record StackAlloc(SizeOf Size) : Expression {
  public SizeOf Size { get; } = Size;

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Size);
  }

  public override string ToString() => $"(StackAlloc Size={Size})";
}
