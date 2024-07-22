namespace Lilac.IL;

public abstract class Node {
  public abstract Node Clone();
}

public abstract class Value : Node {
  // Empty
}

public abstract class Expression : Node {
  // Empty
}

public abstract class Statement : Node {
  // Empty
}

public abstract class Component : Node {
  // Empty
}

public enum Type {
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

public static class TypeMethods {
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

  public static string ToString(this Type type) {
    switch (type) {
      case Type.U8: return "u8";
      case Type.U16: return "u16";
      case Type.U32: return "u32";
      case Type.U64: return "u64";
      case Type.I8: return "i8";
      case Type.I16: return "i16";
      case Type.I32: return "i32";
      case Type.I64: return "i64";
      case Type.F32: return "f32";
      case Type.F64: return "f64";
      case Type.Void: return "void";
      default:
        throw new Exception(); // TODO: nice exception
    }
  }
}

public class Constant : Value {
  public Type Type { get; }
  public object Value { get; }

  public Constant(Type type, object @value) {
    Type = type;
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Constant)) {
      return false;
    }

    Constant other = (Constant)obj;
    return Type.Equals(other.Type) && Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Value);
  }

  public override Constant Clone() => new(Type, Value);
}

public class ID : Value {
  public string Name { get; }

  public ID(string name) {
    Name = name;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ID)) {
      return false;
    }

    ID other = (ID)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override ID Clone() => new(Name);
}

public class GlobalID : ID {
  public GlobalID(string name) : base(name) {
    // Empty
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(GlobalID)) {
      return false;
    }

    GlobalID other = (GlobalID)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override GlobalID Clone() => new(Name);
}

public class ValueExpr : Expression {
  public Value Value { get; }

  public ValueExpr(Value @value) {
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ValueExpr)) {
      return false;
    }

    ValueExpr other = (ValueExpr)obj;
    return Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value);
  }

  public override ValueExpr Clone() => new(Value);
}

public class BinaryOp : Expression {
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

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(BinaryOp)) {
      return false;
    }

    BinaryOp other = (BinaryOp)obj;
    return Op.Equals(other.Op) && Left.Equals(other.Left) &&
           Right.Equals(other.Right);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Left, Right);
  }

  public override BinaryOp Clone() => new(Op, Left, Right);
}

public class UnaryOp : Expression {
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

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(UnaryOp)) {
      return false;
    }

    UnaryOp other = (UnaryOp)obj;
    return Op.Equals(other.Op) && Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Value);
  }

  public override UnaryOp Clone() => new(Op, Value);
}

public abstract class Conversion : Expression {
  public Value Value { get; }
  public Type NewType { get; }

  public Conversion(Value @value, Type newType) {
    Value = @value;
    NewType = newType;
  }

  public override bool Equals(object? obj) {
    // NOTE: this type equality check is a little less strict than usual
    // so that it doesn't have to be rewritten for every conversion.
    if (obj is null || GetType() != obj.GetType()) {
      return false;
    }

    Conversion other = (Conversion)obj;

    return Value.Equals(other.Value) && NewType.Equals(other.NewType);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value, NewType);
  }
}

public class SignTruncConversion : Conversion {
  public SignTruncConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override SignTruncConversion Clone() => new(Value, NewType);
}

public class SignExtendConversion : Conversion {
  public SignExtendConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override SignExtendConversion Clone() => new(Value, NewType);
}

public class TruncIntConversion : Conversion {
  public TruncIntConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override TruncIntConversion Clone() => new(Value, NewType);
}

public class ExtendIntConversion : Conversion {
  public ExtendIntConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override ExtendIntConversion Clone() => new(Value, NewType);
}

public class TruncFloatConversion : Conversion {
  public TruncFloatConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override TruncFloatConversion Clone() => new(Value, NewType);
}

public class ExtendFloatConversion : Conversion {
  public ExtendFloatConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override ExtendFloatConversion Clone() => new(Value, NewType);
}

public class IntToFloatConversion : Conversion {
  public IntToFloatConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override IntToFloatConversion Clone() => new(Value, NewType);
}

public class FloatToIntConversion : Conversion {
  public FloatToIntConversion(Value @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override FloatToIntConversion Clone() => new(Value, NewType);
}

public class Call : Expression {
  public string FuncName { get; }
  public List<Value> Args { get; }

  public Call(string funcName, List<Value> args) {
    FuncName = funcName;
    Args = args;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Call)) {
      return false;
    }

    Call other = (Call)obj;
    return FuncName.Equals(other.FuncName) && Args.SequenceEqual(other.Args);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncName, Args);
  }

  public override Call Clone() => new(FuncName, Args);
}

public class ExternCall : Call {
  public string FuncSource { get; }

  public ExternCall(string funcSource,
                    string funcName,
                    List<Value> args)
    : base(funcName, args) {
    FuncSource = funcSource;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ExternCall)) {
      return false;
    }

    ExternCall other = (ExternCall)obj;
    return FuncSource.Equals(other.FuncSource) &&
           FuncName.Equals(other.FuncName) &&
           Args.SequenceEqual(other.Args);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncSource, FuncName, Args);
  }

  public override ExternCall Clone() => new(FuncSource, FuncName, Args);
}

public class Phi : Expression {
  public List<ID> Ids { get; }

  public Phi(List<ID> ids) {
    Ids = ids;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Phi)) {
      return false;
    }

    Phi other = (Phi)obj;
    return Ids.SequenceEqual(other.Ids);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Ids);
  }

  public override Phi Clone() => new(Ids);
}

public class Definition : Statement {
  public Type Type { get; }
  public ID Id { get; }
  public Expression Rhs { get; }

  public Definition(Type type, ID id, Expression rhs) {
    Type = type;
    Id = id;
    Rhs = rhs;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Definition)) {
      return false;
    }

    Definition other = (Definition)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id) &&
           Rhs.Equals(other.Rhs);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id, Rhs);
  }

  public override Definition Clone() => new(Type, Id, Rhs);
}

public class Label : Statement {
  public string Name { get; }

  public Label(string name) {
    Name = name;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Label)) {
      return false;
    }

    Label other = (Label)obj;
    return Name.Equals(other.Name);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name);
  }

  public override Label Clone() => new(Name);
}

public class Jump : Statement {
  public string Target { get; set; }

  public Jump(string target) {
    Target = target;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Jump)) {
      return false;
    }

    Jump other = (Jump)obj;
    return Target.Equals(other.Target);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target);
  }

  public override Jump Clone() => new(Target);
}

public abstract class CondJump : Jump {
  public Value Cond;

  public CondJump(string target, Value cond) : base(target) {
    Cond = cond;
  }
}

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

public class JumpNotZero : CondJump {
  public JumpNotZero(string target, Value cond) : base(target, cond) {
    // Empty
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(JumpNotZero)) {
      return false;
    }

    JumpNotZero other = (JumpNotZero)obj;
    return Target.Equals(other.Target) && Cond.Equals(other.Cond);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target, Cond);
  }

  public override JumpNotZero Clone() => new(Target, Cond);
}

public class Return : Statement {
  public Value Value { get; }

  public Return(Value @value) {
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Return)) {
      return false;
    }

    Return other = (Return)obj;
    return Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value);
  }

  public override Return Clone() => new(Value);
}

public class VoidCall : Statement {
  public Call Call { get; }

  public VoidCall(Call call) {
    Call = call;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(VoidCall)) {
      return false;
    }

    VoidCall other = (VoidCall)obj;
    return Call.Equals(other.Call);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Call);
  }

  public override VoidCall Clone() => new(Call);
}

public class InlineInstr : Statement {
  public string Target { get; }
  // TODO: store as CodeGen.Instruction
  public string Instr { get; }

  public InlineInstr(string target, string instr) {
    Target = target;
    Instr = instr;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(InlineInstr)) {
      return false;
    }

    InlineInstr other = (InlineInstr)obj;
    return Target.Equals(other.Target) && Instr.Equals(other.Instr);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Target, Instr);
  }

  public override InlineInstr Clone() => new(Target, Instr);
}

public class GlobalDef : Component {
  public Type Type { get; }
  public GlobalID Id { get; }
  public Constant Rhs { get; }

  public GlobalDef(Type type, GlobalID id, Constant rhs) {
    Type = type;
    Id = id;
    Rhs = rhs;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(GlobalDef)) {
      return false;
    }

    GlobalDef other = (GlobalDef)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id) &&
           Rhs.Equals(other.Rhs);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id, Rhs);
  }

  public override GlobalDef Clone() => new(Type, Id, Rhs);
}

public class FuncDef : Component {
  public string Name { get; }
  public List<FuncParam> Params { get; }
  public Type RetType { get; }
  public List<Statement> StmtList { get; }
  public bool Exported { get; }

  public FuncDef(string name,
                 List<FuncParam> @params,
                 Type retType,
                 List<Statement> stmtList,
                 bool exported = false) {
    Name = name;
    Params = @params;
    RetType = retType;
    StmtList = stmtList;
    Exported = exported;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(FuncDef)) {
      return false;
    }

    FuncDef other = (FuncDef)obj;

    return Name.Equals(other.Name) && Params.SequenceEqual(other.Params) &&
           RetType.Equals(other.RetType) &&
           StmtList.SequenceEqual(other.StmtList) &&
           Exported.Equals(other.Exported);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name, Params, RetType, StmtList,
                            Exported);
  }

  public override FuncDef Clone() =>
    new(Name, Params, RetType, StmtList, Exported);
}

public class FuncParam : Node {
  public Type Type { get; }
  public ID Id { get; }

  public FuncParam(Type type, ID id) {
    Type = type;
    Id = id;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(FuncParam)) {
      return false;
    }

    FuncParam other = (FuncParam)obj;
    return Type.Equals(other.Type) && Id.Equals(other.Id);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id);
  }

  public override FuncParam Clone() => new(Type, Id);
}

public class ExternFuncDef : Component {
  public string Source { get; }
  public string Name { get; }
  public List<Type> ParamTypes { get; }
  public Type RetType { get; }

  public ExternFuncDef(string source,
                       string name,
                       List<Type> paramTypes,
                       Type retType) {
    Source = source;
    Name = name;
    ParamTypes = paramTypes;
    RetType = retType;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ExternFuncDef)) {
      return false;
    }

    ExternFuncDef other = (ExternFuncDef)obj;
    return Source.Equals(other.Source) && Name.Equals(other.Name) &&
           ParamTypes.SequenceEqual(other.ParamTypes) &&
           RetType.Equals(other.RetType);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Source, Name, ParamTypes, RetType);
  }

  public override ExternFuncDef Clone() =>
    new(Source, Name, ParamTypes, RetType);
}

public class Program {
  private Dictionary<string, GlobalDef> globalMap;
  private Dictionary<string, FuncDef> funcMap;
  private Dictionary<(string, string), ExternFuncDef> externFuncMap;

  public int GlobalCount => globalMap.Count;
  public int FuncCount => funcMap.Count;
  public int ExternFuncCount => externFuncMap.Count;

  public Program() {
    globalMap = new();
    funcMap = new();
    externFuncMap = new();
  }

  public void AddGlobal(GlobalDef globalDef) {
    globalMap.Add(globalDef.Id.Name, globalDef);
  }

  public IEnumerable<GlobalDef> GetGlobals() {
    foreach (GlobalDef g in globalMap.Values) {
      yield return g;
    }
  }

  public GlobalDef? GetGlobal(string name) {
    return globalMap[name];
  }

  public void AddFunc(FuncDef funcDef) {
    funcMap.Add(funcDef.Name, funcDef);
  }

  public IEnumerable<FuncDef> GetFuncs() {
    foreach (FuncDef f in funcMap.Values) {
      yield return f;
    }
  }

  public FuncDef? GetFunc(string name) {
    return funcMap[name];
  }

  public void AddExternFunc(ExternFuncDef externFuncDef) {
    externFuncMap.Add((externFuncDef.Source, externFuncDef.Name),
                      externFuncDef);
  }

  public IEnumerable<ExternFuncDef> GetExternFuncs() {
    foreach (ExternFuncDef f in externFuncMap.Values) {
      yield return f;
    }
  }

  public ExternFuncDef? GetExternFunc(string source, string name) {
    return externFuncMap[(source, name)];
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Program)) {
      return false;
    }

    Program other = (Program)obj;

    if (GlobalCount != other.GlobalCount) {
      return false;
    }
    foreach (string k in globalMap.Keys) {
      if (!globalMap[k].Equals(other.GetGlobal(k))) {
        return false;
      }
    }

    if (FuncCount != other.FuncCount) {
      return false;
    }
    foreach (string k in funcMap.Keys) {
      if (!funcMap[k].Equals(other.GetFunc(k))) {
        return false;
      }
    }

    if (ExternFuncCount != other.ExternFuncCount) {
      return false;
    }
    foreach ((string, string) k in externFuncMap.Keys) {
      if (!externFuncMap[k].Equals(other.GetExternFunc(k.Item1,
                                     k.Item2))) {
        return false;
      }
    }

    return true;
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), globalMap, funcMap, externFuncMap);
  }
}
