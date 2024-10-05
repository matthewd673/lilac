namespace Lilac.IL;

public record SizeOfPrimitive(Type Type) : SizeOf {
  public Type Type { get; } = Type;

  public override int GetHashCode() => HashCode.Combine(GetType(), Type);

  public override string ToString() => $"(SizeOfPrimitive Type={Type})";
}
