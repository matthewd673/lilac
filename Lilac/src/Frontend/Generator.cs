using Lilac.Frontend.SyntaxExceptions;
using Lilac.IL;

namespace Lilac.Frontend;

public class Generator {
  private Program program;

  public Generator(Program program) {
    this.program = program;
  }

  public string Generate() {
    return GenerateProgram(program);
  }

  protected virtual string GenerateType(IL.Type type) {
    return type switch {
      IL.Type.U8 => "u8",
      IL.Type.U16 => "u16",
      IL.Type.U32 => "u32",
      IL.Type.U64 => "u64",
      IL.Type.I8 => "i8",
      IL.Type.I16 => "i16",
      IL.Type.I32 => "i32",
      IL.Type.I64 => "i64",
      IL.Type.F32 => "f32",
      IL.Type.F64 => "f64",
      IL.Type.Void => "void",
      _ => throw new CannotGenerateException(type),
    };
  }

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

  protected virtual string GenerateGlobalDef(GlobalDef globalDef) {
    return $"global {GenerateType(globalDef.Type)} {GenerateID(globalDef.Id)} " +
           $"= {GenerateConstant(globalDef.Rhs)}";
  }

  protected virtual string GenerateExternFuncDef(ExternFuncDef externFuncDef) {
    return $"extern func {externFuncDef.Source} {externFuncDef.Name} (" +
           $"{GenerateTypeList(externFuncDef.ParamTypes)}) -> " +
           $"{GenerateType(externFuncDef.RetType)}";
  }

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

  protected virtual string GenerateFuncParam(FuncParam funcParam) {
    return $"{GenerateType(funcParam.Type)} {GenerateID(funcParam.Id)}";
  }

  protected virtual string GenerateStatement(Statement stmt) {
    return stmt switch {
      Definition definition => GenerateDefinition(definition),
      Label label => GenerateLabel(label),
      Jump jump => GenerateJump(jump),
      Return @return => GenerateReturn(@return),
      VoidCall voidCall => GenerateVoidCall(voidCall),
      InlineInstr inlineInstr => GenerateInlineInstr(inlineInstr),
      _ => throw new CannotGenerateException(stmt),
    };
  }

  protected virtual string GenerateDefinition(Definition definition) {
    return $"{GenerateType(definition.Type)} {GenerateID(definition.Id)} = " +
           $"{GenerateExpression(definition.Rhs)}";
  }

  protected virtual string GenerateLabel(Label label) {
    return $"{label.Name}:";
  }

  protected virtual string GenerateJump(Jump jump) {
    return jump switch {
      JumpZero jumpZero => $"jz {GenerateValue(jumpZero.Cond)} " +
                           $"{jumpZero.Target}",
      JumpNotZero jumpNotZero => $"jnz {GenerateValue(jumpNotZero.Cond)} " +
                                 $"{jumpNotZero.Target}",
      _ => $"jmp {jump.Target}",
    };
  }

  protected virtual string GenerateReturn(Return @return) {
    return $"ret {GenerateValue(@return.Value)}";
  }

  protected virtual string GenerateVoidCall(VoidCall voidCall) {
    return $"void {GenerateCall(voidCall.Call)}";
  }

  protected virtual string GenerateInlineInstr(InlineInstr inlineInstr) {
    // TODO: syntax is not implemented
    throw new CannotGenerateException(inlineInstr);
  }

  protected virtual string GenerateExpression(Expression expr) {
    return expr switch {
      ValueExpr valueExpr => GenerateValueExpr(valueExpr),
      BinaryOp binaryOp => GenerateBinaryOp(binaryOp),
      UnaryOp unaryOp => GenerateUnaryOp(unaryOp),
      Conversion conversion => GenerateConversion(conversion),
      Call call => GenerateCall(call),
      Phi phi => GeneratePhi(phi),
      _ => throw new CannotGenerateException(expr),
    };
  }

  protected virtual string GenerateValueExpr(ValueExpr valueExpr) {
    return GenerateValue(valueExpr.Value);
  }

  protected virtual string GenerateBinaryOp(BinaryOp binaryOp) {
    return $"{GenerateValue(binaryOp.Left)} " +
           $"{GenerateBinaryOpOperator(binaryOp.Op)} " +
           $"{GenerateValue(binaryOp.Right)}";
  }

  protected virtual string GenerateBinaryOpOperator(BinaryOp.Operator op) {
    return op switch {
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
    };
  }

  protected virtual string GenerateUnaryOp(UnaryOp unaryOp) {
    return $"{GenerateUnaryOpOperator(unaryOp.Op)} " +
           $"{GenerateValue(unaryOp.Value)}";
  }

  protected virtual string GenerateUnaryOpOperator(UnaryOp.Operator op) {
    return op switch {
      UnaryOp.Operator.Neg => "-@",
      UnaryOp.Operator.BoolNot => "!@",
      UnaryOp.Operator.BitNot => "~@",
    };
  }

  protected virtual string GenerateConversion(Conversion conversion) {
    // TODO: syntax is not implemented
    throw new CannotGenerateException(conversion);
  }

  protected virtual string GenerateCall(Call call) {
    return call switch {
      ExternCall externCall => $"extern call {externCall.FuncSource} " +
                               $"{externCall.FuncName} " +
                               $"({GenerateValueList(externCall.Args)})",
      _ => $"call {call.FuncName} ({GenerateValueList(call.Args)})",
    };
  }

  protected virtual string GeneratePhi(Phi phi) {
    return $"phi ({GenerateValueList(new(phi.Ids))})";
  }

  protected virtual string GenerateValue(Value value) {
    return value switch {
      Constant constant => GenerateConstant(constant),
      ID id => GenerateID(id),
      _ => throw new CannotGenerateException(value),
    };
  }

  protected virtual string GenerateConstant(Constant constant) {
    if (constant.Type.IsVoid()) {
      return "void";
    }

    string valStr = constant.Value.ToString();
    if (constant.Type.IsFloat() && !valStr.Contains(".")) {
      valStr += ".";
    }

    return $"{valStr}{GenerateType(constant.Type)}";
  }

  protected virtual string GenerateID(ID id) {
    return id switch {
      GlobalID => $"@{id.Name}",
      ID => $"${id.Name}",
      _ => throw new CannotGenerateException(id),
    };
  }

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