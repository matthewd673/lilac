namespace Lilac.IL;

internal interface INode<T> {
  public T Clone();
}

public abstract class Node<T> : INode<T> where T : Node<T> {
  public abstract T Clone();
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

public interface IValue;

public abstract class Value<T> : Node<Value<T>>, IValue where T : IValue {
  // Empty
}

public class Constant : Value<Constant> {
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

public class ID : Value<ID> {
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

public interface IExpression;

public abstract class Expression<T>
  : Node<Expression<T>>,
    IExpression
    where T : IExpression {
  // Empty
}

public class ValueExpr<U>
  : Expression<ValueExpr<U>>
    where U : Value<U> {
  public Value<U> Value { get; }

  public ValueExpr(Value<U> @value) {
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(ValueExpr<U>)) {
      return false;
    }

    ValueExpr<U> other = (ValueExpr<U>)obj;
    return Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value);
  }

  public override ValueExpr<U> Clone() => new(Value);
}

public class BinaryOp<TLeft, TRight>
  : Expression<BinaryOp<TLeft, TRight>>
    where TLeft : Value<TLeft>
    where TRight : Value<TRight> {
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
  public Value<TLeft> Left { get; }
  public Value<TRight> Right { get; }

  public BinaryOp(Operator op, Value<TLeft> left, Value<TRight> right) {
    Op = op;
    Left = left;
    Right = right;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(BinaryOp<TLeft, TRight>)) {
      return false;
    }

    BinaryOp<TLeft, TRight> other = (BinaryOp<TLeft, TRight>)obj;
    return Op.Equals(other.Op) && Left.Equals(other.Left) &&
           Right.Equals(other.Right);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Left, Right);
  }

  public override BinaryOp<TLeft, TRight> Clone() => new(Op, Left, Right);
}

public class UnaryOp<TValue>
  : Expression<UnaryOp<TValue>> where TValue : Value<TValue> {
  public enum Operator {
    Neg,
    BoolNot,
    BitNot,
  }

  public Operator Op { get; }
  public Value<TValue> Value { get; }

  public UnaryOp(Operator op, Value<TValue> @value) {
    Op = op;
    Value = @value;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(UnaryOp<TValue>)) {
      return false;
    }

    UnaryOp<TValue> other = (UnaryOp<TValue>)obj;
    return Op.Equals(other.Op) && Value.Equals(other.Value);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Op, Value);
  }

  public override UnaryOp<TValue> Clone() => new(Op, Value);
}

public abstract class Conversion<TConversion, TValue>
  : Expression<Conversion<TConversion, TValue>>
  where TConversion : Conversion<TConversion, TValue>
  where TValue : Value<TValue> {
  public Value<TValue> Value { get; }
  public Type NewType { get; }

  public Conversion(Value<TValue> @value, Type newType) {
    Value = @value;
    NewType = newType;
  }

  public override bool Equals(object? obj) {
    // NOTE: this type equality check isn't as strict as usual
    if (obj is not Conversion<TConversion, TValue> other) {
      return false;
    }

    return Value.Equals(other.Value) && NewType.Equals(other.NewType);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Value, NewType);
  }
}

public class SignTruncConversion<TValue>
  : Conversion<SignTruncConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public SignTruncConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override SignTruncConversion<TValue> Clone() => new(Value, NewType);
}

public class SignExtendConversion<TValue>
  : Conversion<SignExtendConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public SignExtendConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override SignExtendConversion<TValue> Clone() => new(Value, NewType);
}

public class TruncIntConversion<TValue>
  : Conversion<TruncIntConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public TruncIntConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override TruncIntConversion<TValue> Clone() => new(Value, NewType);
}

public class ExtendIntConversion<TValue>
  : Conversion<ExtendIntConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public ExtendIntConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override ExtendIntConversion<TValue> Clone() => new(Value, NewType);
}

public class TruncFloatConversion<TValue>
  : Conversion<TruncFloatConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public TruncFloatConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override TruncFloatConversion<TValue> Clone() => new(Value, NewType);
}

public class ExtendFloatConversion<TValue>
  : Conversion<ExtendFloatConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public ExtendFloatConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override ExtendFloatConversion<TValue> Clone() => new(Value, NewType);
}

public class IntToFloatConversion<TValue>
  : Conversion<IntToFloatConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public IntToFloatConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override IntToFloatConversion<TValue> Clone() => new(Value, NewType);
}

public class FloatToIntConversion<TValue>
  : Conversion<FloatToIntConversion<TValue>, TValue>
  where TValue : Value<TValue> {
  public FloatToIntConversion(Value<TValue> @value, Type newType)
    : base(@value, newType) {
    // Empty
  }

  public override FloatToIntConversion<TValue> Clone() => new(Value, NewType);
}

public class Call : Expression<Call> {
  public string FuncName { get; }
  public List<Value<IValue>> Args { get; }

  public Call(string funcName, List<Value<IValue>> args) {
    FuncName = funcName;
    Args = args;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Call)) {
      return false;
    }

    Call other = (Call)obj;
    return FuncName.Equals(other.FuncName) && Args.Equals(other.Args);
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
                    List<Value<IValue>> args)
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
           Args.Equals(other.Args);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), FuncSource, FuncName, Args);
  }

  public override ExternCall Clone() => new(FuncSource, FuncName, Args);
}

public class Phi : Expression<Phi> {
  public List<ID> Ids { get; }

  public Phi(List<ID> ids) {
    Ids = ids;
  }

  public override bool Equals(object? obj) {
    if (obj is null || obj.GetType() != typeof(Phi)) {
      return false;
    }

    Phi other = (Phi)obj;
    return Ids.Equals(other.Ids);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Ids);
  }

  public override Phi Clone() => new(Ids);
}

public interface IStatement;

public abstract class Statement<T>
  : Node<Statement<T>>,
    IStatement {
  // Empty
}

public class Definition : Statement<Definition> {
  public Type Type { get; }
  public ID Id { get; }
  public Expression<IExpression> Rhs { get; }

  public Definition(Type type, ID id, Expression<IExpression> rhs) {
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

public class Label : Statement<Label> {
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

public class Jump : Statement<Jump> {
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
  public Value<IValue> Cond;

  public CondJump(string target, Value<IValue> cond) : base(target) {
    Cond = cond;
  }
}

public class JumpZero : CondJump {
  public JumpZero(string target, Value<IValue> cond) : base(target, cond) {
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
  public JumpNotZero(string target, Value<IValue> cond) : base(target, cond) {
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

public class Return : Statement<Return> {
  public Value<IValue> Value { get; }

  public Return(Value<IValue> @value) {
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

public class VoidCall : Statement<VoidCall> {
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

public class InlineInstr : Statement<InlineInstr> {
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

public interface IComponent;

public abstract class Component<T>
  : Node<Component<T>>,
    IComponent
    where T : IComponent {
  // Empty
}

public class GlobalDef : Component<GlobalDef> {
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

public class FuncDef : Component<FuncDef> {
  public string Name { get; }
  public List<FuncParam> Params { get; }
  public Type RetType { get; }
  public List<Statement<IStatement>> StmtList { get; }
  public bool Exported { get; }

  public FuncDef(string name,
                 List<FuncParam> @params,
                 Type retType,
                 List<Statement<IStatement>> stmtList,
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
    return Name.Equals(other.Name) && Params.Equals(other.Params) &&
           RetType.Equals(other.RetType) && StmtList.Equals(other.StmtList) &&
           Exported.Equals(other.Exported);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Name, Params, RetType, StmtList,
                            Exported);
  }

  public override FuncDef Clone() =>
    new(Name, Params, RetType, StmtList, Exported);
}

public class FuncParam : Node<FuncParam> {
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
    return Type.Equals(other.Type) && Id.Equals(Id);
  }

  public override int GetHashCode() {
    return HashCode.Combine(GetType(), Type, Id);
  }

  public override FuncParam Clone() => new(Type, Id);
}

public class ExternFuncDef : Component<ExternFuncDef> {
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
           ParamTypes.Equals(other.ParamTypes) && RetType.Equals(other.RetType);
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
}
