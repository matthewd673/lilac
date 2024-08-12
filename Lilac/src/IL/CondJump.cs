namespace Lilac.IL;

public abstract class CondJump : Jump {
  public Value Cond;

  public CondJump(string target, Value cond) : base(target) {
    Cond = cond;
  }
}
