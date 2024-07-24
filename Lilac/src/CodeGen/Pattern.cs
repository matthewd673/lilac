using Lilac.IL;

namespace Lilac.CodeGen;

internal static class Pattern {
  public class StatementWildcard : Statement {
    // NOTE: stub

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class DefinitionWildcard : Statement {
    public Expression Rhs { get; }

    public DefinitionWildcard(Expression rhs) {
      Rhs = rhs;
    }

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class InlineInstructionWildcard : Statement {
    // NOTE: stub

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class ExpressionWildcard : Expression {
    // NOTE: stub

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class BinaryOpWildcard : Expression {
    public Value Left { get; }
    public Value Right { get; }

    public BinaryOpWildcard(Value left, Value right) {
      Left = left;
      Right = right;
    }

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class UnaryOpWildcard : Expression {
    public Value Value { get; }

    public UnaryOpWildcard(Value @value) {
      Value = @value;
    }

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class CallWildcard : Call {
    public CallWildcard() : base("", []) {
      // Empty
    }
  }

  public class ValueWildcard : Value {
    // NOTE: stub

    public override Node Clone() {
      throw new NotImplementedException();
    }
  }

  public class IDWildcard : ID {
    public IDWildcard() : base("") {
      // Empty
    }
  }

  public class ConstantWildcard : Constant {
    public ConstantWildcard() : base(IL.Type.Void, 0) {
      // Empty
    }
  }

  public class IntegerConstantWildcard : Constant {
    public IntegerConstantWildcard(object value) : base(IL.Type.I32, value) {
      // Empty
    }
  }

  public class SignedConstantWildcard : Constant {
    public SignedConstantWildcard(object value) : base(IL.Type.I32, value) {
      // Empty
    }
  }

  public class UnsignedConstantWildcard : Constant {
    public UnsignedConstantWildcard(object value) : base(IL.Type.U32, value) {
      // Empty
    }
  }

  public class FloatConstantWildcard : Constant {
    public FloatConstantWildcard(object value) : base(IL.Type.F32, value) {
      // Empty
    }
  }

  public class NumericValueWildcard {
    // NOTE: stub
  }
}