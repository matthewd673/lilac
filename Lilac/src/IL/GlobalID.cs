namespace Lilac.IL;

public class GlobalID(string name) : ID(name) {
  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(GlobalID)) {
      return false;
    }

    GlobalID other = (GlobalID)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override GlobalID Clone() => new(Name);
}
