namespace Lilac.IL;

public class LocalID(string name) : ID(name) {
  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(LocalID)) {
      return false;
    }

    LocalID other = (LocalID)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override LocalID Clone() => new(Name);
}
