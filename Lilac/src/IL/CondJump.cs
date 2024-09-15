namespace Lilac.IL;

public abstract class CondJump(string target, Value cond) : Jump(target) {
  public Value Cond = cond;
}
