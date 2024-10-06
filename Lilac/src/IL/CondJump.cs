namespace Lilac.IL;

public abstract record CondJump(string Target, Value Cond) : Jump(Target) {
  public Value Cond { get; } = Cond;
}
