namespace Lilac.IL;

public class SizeOfPrimitive(Type type) : SizeOf {
  public Type Type { get; } = type;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(SizeOfPrimitive)) {
      return false;
    }

    SizeOfPrimitive other = (SizeOfPrimitive)obj;
    return Type.Equals(other.Type);
  }

  public override int GetHashCode() => HashCode.Combine(GetType(), Type);

  public override SizeOfPrimitive Clone() => new(Type);
}