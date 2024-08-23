namespace Lilac.IL;

public class JumpNotZero(string target, Value cond) : CondJump(target, cond) {
  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(JumpNotZero)) {
      return false;
    }

    JumpNotZero other = (JumpNotZero)obj;
    return Target.Equals(other.Target) && Cond.Equals(other.Cond);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target, Cond);
  }

  public override JumpNotZero Clone() => new(Target, Cond);

  public override string ToString() =>
    $"(JumpNotZero Target={Target} Cond={Cond})";
}
