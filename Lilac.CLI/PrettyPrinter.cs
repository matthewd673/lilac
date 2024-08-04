using Lilac.Frontend;
using Lilac.IL;

namespace Lilac.CLI;

public class PrettyPrinter : Generator {
  public PrettyPrinter(IL.Program program) : base(program) {
    // Empty
  }

  protected override string GenerateType(IL.Type type) {
    return ANSI.Format(base.GenerateType(type), ANSI.Color.Yellow);
  }

  protected override string GenerateConstant(Constant constant) {
    return ANSI.Format(base.GenerateConstant(constant), ANSI.Color.Magenta);
  }

  protected override string GenerateID(ID id) {
    return ANSI.Format(base.GenerateID(id), ANSI.Color.Blue);
  }

  protected override string GenerateBinaryOpOperator(BinaryOp.Operator op) {
    return ANSI.Format(base.GenerateBinaryOpOperator(op), ANSI.Color.Green);
  }

  protected override string GenerateUnaryOpOperator(UnaryOp.Operator op) {
    return ANSI.Format(base.GenerateUnaryOpOperator(op), ANSI.Color.Green);
  }

  protected override string GenerateJump(Jump jump) {
    return ANSI.Format(base.GenerateJump(jump), ANSI.Color.Red);
  }
}