namespace Lilac.IL;

public record GetElementOffset(Value Address, Type ElementType, int Index)
  : Expression {
  public Value Address { get; } = Address;
  public Type ElementType { get; } = ElementType;
  public int Index { get; } = Index;

  public override string ToString() =>
    $"(GetFieldOffset Address={Address} ElementType={ElementType} Index={Index})";
}
