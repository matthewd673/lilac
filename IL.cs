namespace Lilac {
  namespace IL {
    enum Type {
      U8,
      U16,
      U32,
      U64,
      I8,
      I16,
      I32,
      I64,
      F32,
      F64,
      Void,
    }

    static class TypeMethods {
      public static bool IsUnsigned(this Type type) {
        switch (type) {
          case Type.U8:
          case Type.U16:
          case Type.U32:
          case Type.U64:
            return true;
          default:
            return false;
        }
      }

      public static bool IsSigned(this Type type) {
        switch (type) {
          case Type.I8:
          case Type.I16:
          case Type.I32:
          case Type.I64:
            return true;
          default:
            return false;
        }
      }

      public static bool IsInteger(this Type type) {
        return type.IsUnsigned() || type.IsSigned();
      }

      public static bool IsFloat(this Type type) {
        switch (type) {
          case Type.F32:
          case Type.F64:
            return true;
          default:
            return false;
        }
      }

      public static bool IsNumeric(this Type type) {
        return type.IsInteger() || type.IsFloat();
      }

      public static bool IsVoid(this Type type) {
        switch (type) {
          case Type.Void:
            return true;
          default:
            return false;
        }
      }
    }

    class Value {
      // Empty
    }

    class Constant : Value {
      public Type Type { get; }
      public object Value { get; }

      public Constant(Type type, object @value) {
        Type = type;
        Value = @value;
      }
    }

    class ID : Value {
      public string Name { get; set; }

      public ID(string name) {
        Name = name;
      }
    }

    class GlobalID : ID {
      public GlobalID(string name) : base(name) {
        // Empty
      }
    }

    class Expression {
      // Empty
    }

    class ValueExpr : Expression {
      public Value Value { get; }

      public ValueExpr(Value @value) {
        Value = @value;
      }
    }

    class BinaryOp : Expression {
      public enum Operator {
        Add,
        Sub,
        Mul,
        Div,
        Eq,
        Neq,
        Lt,
        Gt,
        Leq,
        Geq,
        BoolAnd,
        BoolOr,
        BitLs,
        BitRs,
        BitAnd,
        BitOr,
        BitXor,
      }

      public Operator Op { get; }
      public Value Left { get; }
      public Value Right { get; }

      public BinaryOp(Operator op, Value left, Value right) {
        Op = op;
        Left = left;
        Right = right;
      }
    }

    class UnaryOp : Expression {
      public enum Operator {
        Neg,
        BoolNot,
        BitNot,
      }

      public Operator Op { get; }
      public Value Value { get; }

      public UnaryOp(Operator op, Value @value) {
        Op = op;
        Value = @value;
      }
    }

    abstract class Conversion : Expression {
      public Value Value { get; protected set; }
      public Type NewType { get; protected set; }

      public Conversion(Value @value, Type newType) {
        Value = @value;
        NewType = newType;
      }
    }

    class SignTruncConversion : Conversion {
      public SignTruncConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class SignExtendConversion : Conversion {
      public SignExtendConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class TruncIntConversion : Conversion {
      public TruncIntConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class ExtendIntConversion : Conversion {
      public ExtendIntConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class TruncFloatConversion : Conversion {
      public TruncFloatConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class ExtendFloatConversion : Conversion {
      public ExtendFloatConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class IntToFloatConversion : Conversion {
      public IntToFloatConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class FloatToIntConversion : Conversion {
      public FloatToIntConversion(Value @value, Type newType)
        : base(@value, newType) {
        // Empty
      }
    }

    class Call : Expression {
      public string FuncName { get; protected set; }
      public Value[] Args { get; protected set; }

      public Call(string funcName, Value[] args) {
        FuncName = funcName;
        Args = args;
      }
    }

    class ExternCall : Call {
      public string FuncSource { get; }

      public ExternCall(string funcSource, string funcName, Value[] args)
        : base(funcName, args) {
        FuncSource = funcSource;
      }
    }

    class Phi : Expression {
      public ID[] Ids { get; }

      public Phi(ID[] ids) {
        Ids = ids;
      }
    }

    class Statement {
      // Empty
    }

    class Definition : Statement {
      public Type Type { get; }
      public ID Id { get; }
      public Expression Rhs { get; }

      public Definition(Type type, ID id, Expression rhs) {
        Type = type;
        Id = id;
        Rhs = rhs;
      }
    }

    class Label : Statement {
      public string Name { get; }

      public Label(string name) {
        Name = name;
      }
    }

    class Jump : Statement {
      public string Target { get; }

      public Jump(string target) {
        Target = target;
      }
    }

    abstract class CondJump : Jump {
      public Value Cond;

      public CondJump(string target, Value cond) : base(target) {
        Cond = cond;
      }
    }

    class JumpZero : CondJump {
      public JumpZero(string target, Value cond) : base(target, cond) {
        // Empty
      }
    }

    class JumpNotZero : CondJump {
      public JumpNotZero(string target, Value cond) : base(target, cond) {
        // Empty
      }
    }

    class Return : Statement {
      public Value Value { get; }

      public Return(Value @value) {
        Value = @value;
      }
    }

    class VoidCall : Statement {
      public Call Call { get; }

      public VoidCall(Call call) {
        Call = call;
      }
    }

    class InlineInstr : Statement {
      public string Target { get; }
      // TODO: store as CodeGen.Instruction
      public string Instr { get; }

      public InlineInstr(string target, string instr) {
        Target = target;
        Instr = instr;
      }
    }

    class Component {
      // Empty
    }

    class GlobalDef : Component {
      public Type Type { get; }
      public GlobalID Id { get; }
      public Constant Rhs { get; }

      public GlobalDef(Type type, GlobalID id, Constant rhs) {
        Type = type;
        Id = id;
        Rhs = rhs;
      }
    }

    class FuncDef : Component {
      public string Name { get; }
      public FuncParam[] Params { get; }
      public Type RetType { get; }
      public Statement[] StmtList { get; }
      public bool Exported { get; }

      public FuncDef(string name,
                     FuncParam[] @params,
                     Type retType,
                     Statement[] stmtList,
                     bool exported) {
        Name = name;
        Params = @params;
        RetType = retType;
        StmtList = stmtList;
        Exported = exported;
      }
    }

    class FuncParam {
      public Type Type { get; }
      public ID Id { get; }

      public FuncParam(Type type, ID id) {
        Type = type;
        Id = id;
      }
    }

    class ExternFuncDef : Component {
      public string Source { get; }
      public string Name { get; }
      public Type[] ParamTypes { get; }
      public Type RetType { get; }

      public ExternFuncDef(string source,
                           string name,
                           Type[] paramTypes,
                           Type retType) {
        Source = source;
        Name = name;
        ParamTypes = paramTypes;
        RetType = retType;
      }
    }

    class Program {
      private Dictionary<string, GlobalDef> globalMap;
      private Dictionary<string, FuncDef> funcMap;
      private Dictionary<(string, string), ExternFuncDef> externFuncMap;

      public Program() {
        globalMap = new();
        funcMap = new();
        externFuncMap = new();
      }
    }
  }
}
