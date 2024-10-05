namespace Lilac.IL;

public record Load(Type Type, Value Address) : Expression {
  public Type Type { get; } = Type;
  public Value Address { get; } = Address;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), Type, Address);

  public override string ToString() => $"(Load Type={Type} Address={Address})";
}
