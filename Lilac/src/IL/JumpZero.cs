namespace Lilac.IL;

public record JumpZero(string Target, Value Cond) : CondJump(Target, Cond) {
  public override string ToString() =>
    $"(JumpZero Target={Target} Cond={Cond})";
}
