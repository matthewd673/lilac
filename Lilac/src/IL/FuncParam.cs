namespace Lilac.IL;

public class FuncParam(Type type, LocalID id) : Node {
  public Type Type { get; } = type;
  public LocalID Id { get; } = id;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(FuncParam)) {
      return false;
    }

    FuncParam other = (FuncParam)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id);
  }

  public override FuncParam Clone() => new(Type, Id);

  public override string ToString() =>
    $"(FuncParam Type={Type} Id={Id})";
}
