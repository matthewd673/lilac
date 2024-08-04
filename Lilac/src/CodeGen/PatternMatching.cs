using Lilac.IL;

namespace Lilac.CodeGen;

internal static class PatternMatching {
  public static bool Matches(Node rule, Node obj) {
    return rule switch {
      // WILDCARDS
      // Statement wildcards
      Pattern.DefinitionWildcard ruleDef =>
        obj is Definition objDef && Matches(ruleDef.Rhs, objDef.Rhs),
      Pattern.InlineInstrWildcard => obj is InlineInstr,
      Pattern.StatementWildcard => obj is Statement,
      // Expression wildcards
      Pattern.BinaryOpWildcard ruleBinOpW =>
        obj is BinaryOp objBinOp && Matches(ruleBinOpW.Left, objBinOp.Left) &&
        Matches(ruleBinOpW.Right, objBinOp.Right),
      Pattern.UnaryOpWildcard ruleUnOpW =>
        obj is UnaryOp objUnOp && Matches(ruleUnOpW.Value, objUnOp.Value),
      Pattern.CallWildcard => obj is Call,
      Pattern.ExpressionWildcard => obj is Expression,
      // Value wildcards
      Pattern.IDWildcard => obj is ID,
      Pattern.ConstantWildcard => obj is Constant,
      Pattern.IntegerConstantWildcard ruleIntConst =>
        obj is Constant objIntConst && objIntConst.Type.IsInteger() &&
        ConstantValueMatches(ruleIntConst.Value, objIntConst.Value),
      Pattern.SignedConstantWildcard ruleSConst =>
        obj is Constant objSConst && objSConst.Type.IsSigned() &&
        ConstantValueMatches(ruleSConst.Value, objSConst.Value),
      Pattern.UnsignedConstantWildcard ruleUConst =>
        obj is Constant objUConst && objUConst.Type.IsUnsigned() &&
        ConstantValueMatches(ruleUConst.Value, objUConst.Value),
      Pattern.FloatConstantWildcard ruleFloatConst =>
        obj is Constant objFloatConst && objFloatConst.Type.IsFloat() &&
        ConstantValueMatches(ruleFloatConst.Value, objFloatConst.Value),
      Pattern.ValueWildcard => obj is Value,
      // NON-WILDCARDS
      // Statements
      VoidCall ruleVCall =>
        obj is VoidCall objVCall &&
        Matches(ruleVCall.Call, objVCall.Call),
      Return ruleRet =>
        obj is Return objRet &&
        Matches(ruleRet.Value, objRet.Value),
      // Expressions
      BinaryOp ruleBinOp =>
        obj is BinaryOp objBinOp && ruleBinOp.Op.Equals(objBinOp.Op) &&
        Matches(ruleBinOp.Left, objBinOp.Left) &&
        Matches(ruleBinOp.Right, objBinOp.Right),
      UnaryOp ruleUnOp =>
        obj is UnaryOp objUnOp && ruleUnOp.Op.Equals(objUnOp.Op) &&
        Matches(ruleUnOp.Value, objUnOp.Value),
      // Values
      Constant ruleConst =>
        obj is Constant objConst && ruleConst.Type.Equals(objConst.Type) &&
        ConstantValueMatches(ruleConst.Value, objConst.Value),
      _ => false,
    };
  }

  private static bool ConstantValueMatches(object rule, object value) {
    if (rule is Pattern.NumericValueWildcard) {
      return true;
    }

    return rule.Equals(value);
  }
}