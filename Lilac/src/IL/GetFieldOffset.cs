namespace Lilac.IL;

public record GetFieldOffset(Value Address, string StructName, int Index)
  : Expression {
  public Value Address { get; } = Address;
  public string StructName { get; } = StructName;
  public int Index { get; } = Index;

  public override string ToString() =>
    $"(GetFieldOffset Address={Address} StructName={StructName} Index={Index})";
}
