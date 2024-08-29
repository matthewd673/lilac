namespace Lilac.IL;

public class GlobalDef(Type type, GlobalID id, Constant rhs)
  : Component, INamed {
  public Type Type { get; } = type;
  public GlobalID Id { get; } = id;
  public Constant Rhs { get; } = rhs;

  public string Name => Id.Name;

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(GlobalDef)) {
      return false;
    }

    GlobalDef other = (GlobalDef)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id) &&
           Rhs.Equals(other.Rhs);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id, Rhs);
  }

  public override GlobalDef Clone() => new(Type, Id, Rhs);

  public override string ToString() =>
    $"(GlobalDef Type={Type} Id={Id} Rhs={Rhs})";
}
