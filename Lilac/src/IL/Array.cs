namespace Lilac.IL;

public class Array(Type elementType, int length) : Expression {
  public Type ElementType { get; }  = elementType;
  public int Length { get; } = length;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Array)) {
      return false;
    }

    Array other = (Array)obj;
    return ElementType.Equals(other.ElementType) && Length.Equals(other.Length);
  }

  public override int GetHashCode() =>
    HashCode.Combine(GetType(), ElementType, Length);

  public override Array Clone() => new(ElementType, Length);

  public override string ToString() =>
    $"(Array ElementType={ElementType} Length={Length})";
}
