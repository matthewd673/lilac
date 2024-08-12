namespace Lilac.IL;

public class GlobalDef : Component {
  public Type Type { get; }
  public GlobalID Id { get; }
  public Constant Rhs { get; }

  public GlobalDef(Type type, GlobalID id, Constant rhs) {
    Type = type;
    Id = id;
    Rhs = rhs;
  }

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
}
