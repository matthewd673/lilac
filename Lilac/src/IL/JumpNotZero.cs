namespace Lilac.IL;

public record JumpNotZero(string Target, Value Cond) : CondJump(Target, Cond) {
  public override string ToString() =>
    $"(JumpNotZero Target={Target} Cond={Cond})";
}
