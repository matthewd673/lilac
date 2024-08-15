using System.Buffers.Binary;
using Lilac.Frontend.SyntaxExceptions;
using Lilac.IL;
using Lilac.IL.Math;
using Type = Lilac.IL.Type;

namespace Lilac.Frontend;

public class Generator(Program program) {
  public string Generate() =>
    GenerateProgram(program);

  protected virtual string GenerateType(IL.Type type) =>
    type switch {
      Type.U8 => "u8",
      Type.U16 => "u16",
      Type.U32 => "u32",
      Type.U64 => "u64",
      Type.I8 => "i8",
      Type.I16 => "i16",
      Type.I32 => "i32",
      Type.I64 => "i64",
      Type.F32 => "f32",
      Type.F64 => "f64",
      Type.Pointer => "ptr",
      Type.Void => "void",
      _ => throw new CannotGenerateException(type),
    };

  protected virtual string GenerateProgram(Program program) {
    string str = "";

    foreach (GlobalDef g in program.GetGlobals()) {
      str += $"{GenerateGlobalDef(g)}\n";
    }

    foreach (ExternFuncDef f in program.GetExternFuncs()) {
      str += $"{GenerateExternFuncDef(f)}\n";
    }

    foreach (FuncDef f in program.GetFuncs()) {
      str += $"{GenerateFuncDef(f)}\n";
    }

    return str;
  }

  protected virtual string GenerateGlobalDef(GlobalDef globalDef) =>
    $"global {GenerateType(globalDef.Type)} {GenerateID(globalDef.Id)} " +
      $"= {GenerateConstant(globalDef.Rhs)}";

  protected virtual string GenerateExternFuncDef(ExternFuncDef externFuncDef) =>
    $"extern func {externFuncDef.Source} {externFuncDef.Name} (" +
      $"{GenerateTypeList(externFuncDef.ParamTypes)}) -> " +
      $"{GenerateType(externFuncDef.RetType)}";

  protected virtual string GenerateFuncDef(FuncDef funcDef) {
    string str =
      $"func {funcDef.Name} ({GenerateFuncParamList(funcDef.Params)}) " +
      $"-> {GenerateType(funcDef.RetType)}\n";

    foreach (Statement s in funcDef.StmtList) {
      str += $"  {GenerateStatement(s)}\n";
    }

    str += "end";

    return str;
  }

  protected virtual string GenerateFuncParam(FuncParam funcParam) =>
    $"{GenerateType(funcParam.Type)} {GenerateID(funcParam.Id)}";

  protected virtual string GenerateStatement(Statement stmt) =>
    stmt switch {
      Definition definition => GenerateDefinition(definition),
      Label label => GenerateLabel(label),
      Jump jump => GenerateJump(jump),
      Return @return => GenerateReturn(@return),
      VoidCall voidCall => GenerateVoidCall(voidCall),
      InlineInstr inlineInstr => GenerateInlineInstr(inlineInstr),
      Store store => GenerateStore(store),
      _ => throw new CannotGenerateException(stmt),
    };

  protected virtual string GenerateDefinition(Definition definition) =>
    $"{GenerateType(definition.Type)} {GenerateID(definition.Id)} = " +
      $"{GenerateExpression(definition.Rhs)}";

  protected virtual string GenerateLabel(Label label) =>
    $"{label.Name}:";

  protected virtual string GenerateJump(Jump jump) =>
    jump switch {
      JumpZero jumpZero => $"jz {GenerateValue(jumpZero.Cond)} " +
                           $"{jumpZero.Target}",
      JumpNotZero jumpNotZero => $"jnz {GenerateValue(jumpNotZero.Cond)} " +
                                 $"{jumpNotZero.Target}",
      _ => $"jmp {jump.Target}",
    };

  protected virtual string GenerateReturn(Return @return) =>
    $"ret {GenerateValue(@return.Value)}";

  protected virtual string GenerateVoidCall(VoidCall voidCall) =>
    $"void {GenerateCall(voidCall.Call)}";

  protected virtual string GenerateInlineInstr(InlineInstr inlineInstr) =>
    // TODO: syntax is not implemented
    throw new CannotGenerateException(inlineInstr);

  protected virtual string GenerateStore(Store store) =>
    $"store {GenerateType(store.Type)} {GenerateValue(store.Address)} " +
    $"{GenerateValue(store.Value)}";

  protected virtual string GenerateExpression(Expression expr) =>
    expr switch {
      ValueExpr valueExpr => GenerateValueExpr(valueExpr),
      BinaryOp binaryOp => GenerateBinaryOp(binaryOp),
      UnaryOp unaryOp => GenerateUnaryOp(unaryOp),
      Conversion conversion => GenerateConversion(conversion),
      Call call => GenerateCall(call),
      Phi phi => GeneratePhi(phi),
      StackAlloc stackAlloc => GenerateStackAlloc(stackAlloc),
      Load load => GenerateLoad(load),
      _ => throw new CannotGenerateException(expr),
    };

  protected virtual string GenerateValueExpr(ValueExpr valueExpr) =>
    GenerateValue(valueExpr.Value);

  protected virtual string GenerateBinaryOp(BinaryOp binaryOp) =>
    $"{GenerateValue(binaryOp.Left)} {GenerateBinaryOpOperator(binaryOp.Op)} " +
      $"{GenerateValue(binaryOp.Right)}";

  protected virtual string GenerateBinaryOpOperator(BinaryOp.Operator op) =>
    op switch {
      BinaryOp.Operator.Add => "+",
      BinaryOp.Operator.Sub => "-",
      BinaryOp.Operator.Mul => "*",
      BinaryOp.Operator.Div => "/",
      BinaryOp.Operator.Mod => "%",
      BinaryOp.Operator.Eq => "==",
      BinaryOp.Operator.Neq => "!=",
      BinaryOp.Operator.Lt => "<",
      BinaryOp.Operator.Gt => ">",
      BinaryOp.Operator.Leq => "<=",
      BinaryOp.Operator.Geq => ">=",
      BinaryOp.Operator.BoolAnd => "&&",
      BinaryOp.Operator.BoolOr => "||",
      BinaryOp.Operator.BitLs => "<<",
      BinaryOp.Operator.BitRs => ">>",
      BinaryOp.Operator.BitAnd => "&",
      BinaryOp.Operator.BitOr => "|",
      BinaryOp.Operator.BitXor => "^",
      _ => throw new CannotGenerateException(op),
    };

  protected virtual string GenerateUnaryOp(UnaryOp unaryOp) =>
    $"{GenerateUnaryOpOperator(unaryOp.Op)}{GenerateValue(unaryOp.Value)}";

  protected virtual string GenerateUnaryOpOperator(UnaryOp.Operator op) =>
    op switch {
      UnaryOp.Operator.Neg => "-@",
      UnaryOp.Operator.BoolNot => "!@",
      UnaryOp.Operator.BitNot => "~@",
      _ => throw new CannotGenerateException(op),
    };

  protected virtual string GenerateConversion(Conversion conversion) {
    // TODO: syntax is not implemented
    throw new CannotGenerateException(conversion);
  }

  protected virtual string GenerateCall(Call call) =>
    call switch {
      ExternCall externCall => $"extern call {externCall.FuncSource} " +
                               $"{externCall.FuncName} " +
                               $"({GenerateValueList(externCall.Args)})",
      _ => $"call {call.FuncName} ({GenerateValueList(call.Args)})",
    };

  protected virtual string GeneratePhi(Phi phi) =>
    $"phi ({GenerateValueList(new(phi.Ids))})";

  protected virtual string GenerateStackAlloc(StackAlloc stackAlloc) =>
    $"stack_alloc {GenerateType(stackAlloc.Type)}";

  protected virtual string GenerateLoad(Load load) =>
    $"load {GenerateType(load.Type)} {GenerateValue(load.Address)}";

  protected virtual string GenerateValue(Value value) =>
    value switch {
      Constant constant => GenerateConstant(constant),
      ID id => GenerateID(id),
      _ => throw new CannotGenerateException(value),
    };

  protected virtual string GenerateConstant(Constant constant) {
    if (constant.Type.IsVoid()) {
      return "void";
    }

    string valStr = ValueEncoder.StringifyValue(constant.Type, constant.Value);
    // easy patch for generating floats with 0s in the decimal
    if (constant.Type.IsFloat() && !valStr.Contains('.')) {
      valStr += ".";
    }

    return $"{valStr}{GenerateType(constant.Type)}";
  }

  protected virtual string GenerateID(ID id) =>
    id switch {
      GlobalID => $"@{id.Name}",
      LocalID => $"${id.Name}",
      _ => throw new CannotGenerateException(id),
    };

  protected string GenerateTypeList(List<IL.Type> typeList) {
    string str = "";

    foreach (IL.Type t in typeList) {
      str += $"{GenerateType(t)}, ";
    }

    if (str.Length > 2) {
      str = str.Remove(str.Length - 2);
    }

    return str;
  }

  protected string GenerateFuncParamList(List<FuncParam> funcParamList) {
    string str = "";

    foreach (FuncParam p in funcParamList) {
      str += $"{GenerateFuncParam(p)}, ";
    }

    if (str.Length > 2) {
      str = str.Remove(str.Length - 2);
    }

    return str;
  }

  protected string GenerateValueList(List<Value> valueList) {
    string str = "";

    foreach (Value v in valueList) {
      str += $"{GenerateValue(v)}, ";
    }

    if (str.Length > 2) {
      str = str.Remove(str.Length - 2);
    }

    return str;
  }
}