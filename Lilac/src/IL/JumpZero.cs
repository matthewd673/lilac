namespace Lilac.IL;

public class JumpZero : CondJump {
  public JumpZero(string target, Value cond) : base(target, cond) {
    // Empty
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(JumpZero)) {
      return false;
    }

    JumpZero other = (JumpZero)obj;
    return Target.Equals(other.Target) && Cond.Equals(other.Cond);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target, Cond);
  }

  public override JumpZero Clone() => new(Target, Cond);
}
