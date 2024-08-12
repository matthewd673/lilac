namespace Lilac.IL;

public class Jump : Statement {
  public string Target { get; set; }

  public Jump(string target) {
    Target = target;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Jump)) {
      return false;
    }

    Jump other = (Jump)obj;
    return Target.Equals(other.Target);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target);
  }

  public override Jump Clone() => new(Target);
}
