namespace Lilac.IL;

public record Store(Type Type, Value Address, Value Value) : Statement {
  public Type Type { get; } = Type;
  public Value Address { get; } = Address;
  public Value Value { get; } = Value;

  public override string ToString() =>
    $"(Store Type={Type} Address={Address} Value={Value})";
}
