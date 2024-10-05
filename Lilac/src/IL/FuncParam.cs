namespace Lilac.IL;

public record FuncParam(Type Type, LocalID Id) : Node {
  public Type Type { get; } = Type;
  public LocalID Id { get; } = Id;

  public override int GetHashCode() => HashCode.Combine(GetType(), Type, Id);

  public override string ToString() =>
    $"(FuncParam Type={Type} Id={Id})";
}
