namespace Lilac.IL;

public record Array(Type ElementType, int Length) : Expression {
  public Type ElementType { get; }  = ElementType;
  public int Length { get; } = Length;

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), ElementType, Length);

  public override string ToString() =>
    $"(Array ElementType={ElementType} Length={Length})";
}
