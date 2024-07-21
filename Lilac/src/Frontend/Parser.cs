using Lilac.IL;
using System.Text.RegularExpressions;
using Lilac.Frontend.SyntaxExceptions;

namespace Lilac.Frontend;

public class Parser {
  private Scanner scanner;
  private Token nextToken;

  public static IL.Program ParseFile(string filename) {
    string content = File.ReadAllText(filename);
    Parser parser = new(content);
    return parser.Parse();
  }

  public Parser(string str) {
    scanner = new(str);
    nextToken = new(TokenType.None, "", new(0, 0));
  }

  public IL.Program Parse() {
    nextToken = scanner.ScanNext();
    return ParseProgram();
  }

  public List<IL.Statement> ParseStatement() {
    nextToken = scanner.ScanNext();
    if (See(TokenType.EOF)) {
      return new();
    }

    return ParseStmt();
  }

  private bool See(params TokenType[] types) {
    foreach (TokenType t in types) {
      if (nextToken.Type == t) {
        return true;
      }
    }

    return false;
  }

  private Token Eat(params TokenType[] types) {
    foreach (TokenType t in types) {
      if (nextToken.Type != t) {
        continue;
      }

      Token eaten = nextToken;
      nextToken = scanner.ScanNext();
      return eaten;
    }

    throw new UnexpectedToken(nextToken.Position, types, nextToken);
  }

  private IL.Program ParseProgram() {
    IL.Program program = new();

    // parse top level components
    while (!See(TokenType.EOF)) {
      // ignore newlines here
      if (See(TokenType.NewLine)) {
        Eat(TokenType.NewLine);
      }
      // global def
      else if (See(TokenType.Global)) {
        program.AddGlobal(ParseGlobalDef());
      }
      // func def
      else if (See(TokenType.Func)) {
        program.AddFunc(ParseFuncDef());
      }
      // extern func def
      else if (See(TokenType.Extern)) {
        program.AddExternFunc(ParseExternFuncDef());
      }
      else {
        throw new Exception(); // TODO: nice error
      }
    }

    Eat(TokenType.EOF);

    return program;
  }

  private List<IL.Statement> ParseStmtList() {
    List<IL.Statement> stmtList = new();

    // parse stmts until we reach the end
    while (!See(TokenType.EOF, TokenType.End, TokenType.Func)) {
      stmtList.AddRange(ParseStmt());
    }

    return stmtList;
  }

  private List<IL.Statement> ParseStmt() {
    // empty stmt
    if (See(TokenType.NewLine)) {
      Eat(TokenType.NewLine);
      return new();
    }
    // definition
    else if (See(TokenType.Type)) {
      string typeStr = Eat(TokenType.Type).Image;
      IL.Type type = TypeFromString(typeStr);

      if (!type.IsNumeric()) {
        throw new Exception(); // TODO: nice exception
      }

      string idStr = Eat(TokenType.ID, TokenType.GlobalID).Image;
      IL.ID id = IdFromString(idStr);

      Eat(TokenType.Assignment);

      IL.Expression rhs = ParseExpr();

      return new() { new IL.Definition(type, id, rhs) };
    }
    // label
    else if (See(TokenType.Label)) {
      string labelStr = Eat(TokenType.Label).Image;
      labelStr = labelStr.Remove(labelStr.Length - 1); // remove ':'

      return new() { new IL.Label(labelStr) };
    }
    // jump
    else if (See(TokenType.Jump)) {
      Eat(TokenType.Jump);
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new IL.Jump(targetStr) };
    }
    // jump zero
    else if (See(TokenType.JumpZero)) {
      Eat(TokenType.JumpZero);
      IL.Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new IL.JumpZero(targetStr, @value) };
    }
    // jump not zero
    else if (See(TokenType.JumpNotZero)) {
      Eat(TokenType.JumpNotZero);
      IL.Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new IL.JumpNotZero(targetStr, @value) };
    }
    // return
    else if (See(TokenType.Return)) {
      Eat(TokenType.Return);
      IL.Value @value = ParseValue();

      return new() { new IL.Return(@value) };
    }
    // void call
    else if (See(TokenType.VoidConst)) {
      Eat(TokenType.VoidConst);
      IL.Call call = ParseCall();

      return new() { new IL.VoidCall(call) };
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.Expression ParseExpr() {
    // value or binary op
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst,
            TokenType.ID, TokenType.GlobalID)) {
      IL.Value lVal = ParseValue();

      // if see a binary op, parse that
      // otherwise, we're done
      if (!See(TokenType.BinaryOp)) {
        return new IL.ValueExpr(lVal);
      }

      Token binopTok = Eat(TokenType.BinaryOp);
      IL.Value rVal = ParseValue();

      return BinOpFromToken(binopTok, lVal, rVal);
    }
    // unary op
    else if (See(TokenType.UnaryOp)) {
      Token unopTok = Eat(TokenType.UnaryOp);
      IL.Value @value = ParseValue();

      return UnOpFromToken(unopTok, @value);
    }
    // calls
    else if (See(TokenType.Call, TokenType.Extern)) {
      return ParseCall();
    }
    // phi function
    else if (See(TokenType.Phi)) {
      Eat(TokenType.Phi);

      // eat id list
      Eat(TokenType.LeftParen);
      List<IL.ID> ids = ParseIdList().ToList();
      Eat(TokenType.RightParen);

      return new IL.Phi(ids);
    }

    throw new Exception(); // TODO: nice error
  }

  private IL.Call ParseCall() {
    // func call
    if (See(TokenType.Call)) {
      // eat func name
      Eat(TokenType.Call);
      string funcName = Eat(TokenType.Name).Image;

      // eat args
      Eat(TokenType.LeftParen);
      List<IL.Value> args = ParseCallArgs().ToList();
      Eat(TokenType.RightParen);

      return new IL.Call(funcName, args);
    }
    // extern func call
    else if (See(TokenType.Extern)) {
      // eat func source and name
      Eat(TokenType.Extern);
      Eat(TokenType.Call);
      string funcSource = Eat(TokenType.Name).Image;
      string funcName = Eat(TokenType.Name).Image;

      // eat args
      Eat(TokenType.LeftParen);
      List<IL.Value> args = ParseCallArgs().ToList();
      Eat(TokenType.RightParen);

      return new IL.ExternCall(funcSource, funcName, args);
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.Value ParseValue() {
    // constant
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst)) {
      return ParseConstant();
    }
    // void constant
    else if (See(TokenType.VoidConst)) {
      Eat(TokenType.VoidConst);
      return new IL.Constant(IL.Type.Void, null);
    }
    // id
    else if (See(TokenType.ID, TokenType.GlobalID)) {
      string idStr = Eat(TokenType.ID, TokenType.GlobalID).Image;
      return IdFromString(idStr);
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.Constant ParseConstant() {
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst)) {
      string constStr = Eat(TokenType.UIntConst, TokenType.IntConst,
                            TokenType.FloatConst).Image;
      return ConstantFromString(constStr);
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.GlobalDef ParseGlobalDef() {
    Eat(TokenType.Global);

    string typeStr = Eat(TokenType.Type).Image;
    IL.Type type = TypeFromString(typeStr);

    string idStr = Eat(TokenType.GlobalID).Image;
    IL.GlobalID id = GlobalIdFromString(idStr);

    Eat(TokenType.Assignment);

    IL.Constant rhs = ParseConstant(); // rhs of GlobalDef is always a Constant

    return new IL.GlobalDef(type, id, rhs);
  }

  private IL.FuncDef ParseFuncDef() {
    Eat(TokenType.Func);
    string name = Eat(TokenType.Name).Image;

    Eat(TokenType.LeftParen);
    List<IL.FuncParam> funcParams = ParseFuncParams().ToList();
    Eat(TokenType.RightParen);

    Eat(TokenType.Arrow);
    string retTypeStr = Eat(TokenType.Type, TokenType.VoidConst).Image;
    IL.Type retType = TypeFromString(retTypeStr);
    Eat(TokenType.NewLine);

    List<IL.Statement> stmtList = ParseStmtList();

    Eat(TokenType.End);

    return new IL.FuncDef(name, funcParams, retType, stmtList);
  }

  private IL.ExternFuncDef ParseExternFuncDef() {
    Eat(TokenType.Extern);
    Eat(TokenType.Func);
    string source = Eat(TokenType.Name).Image;
    string name = Eat(TokenType.Name).Image;

    Eat(TokenType.LeftParen);
    List<IL.Type> funcParamTypes = ParseExternFuncParamTypes().ToList();
    Eat(TokenType.RightParen);

    Eat(TokenType.Arrow);
    string retTypeStr = Eat(TokenType.Type, TokenType.VoidConst).Image;
    IL.Type retType = TypeFromString(retTypeStr);
    Eat(TokenType.NewLine);

    return new IL.ExternFuncDef(source, name, funcParamTypes, retType);
  }

  private IEnumerable<IL.FuncParam> ParseFuncParams() {
    // epsilon
    if (See(TokenType.RightParen)) {
      yield break;
    }

    string typeStr = Eat(TokenType.Type).Image;
    IL.Type type = TypeFromString(typeStr);

    string idStr = Eat(TokenType.ID).Image;
    IL.ID id = IdFromString(idStr);

    yield return new IL.FuncParam(type, id);

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (IL.FuncParam p in ParseFuncParams()) {
      yield return p;
    }
  }

  private IEnumerable<IL.Type> ParseExternFuncParamTypes() {
    // epsilon
    if (See(TokenType.RightParen)) {
      yield break;
    }

    string typeStr = Eat(TokenType.Type).Image;
    IL.Type type = TypeFromString(typeStr);

    yield return type;

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (IL.Type t in ParseExternFuncParamTypes()) {
      yield return t;
    }
  }

  private IEnumerable<IL.Value> ParseCallArgs() {
    // epsilon
    if (See(TokenType.RightParen)) {
      yield break;
    }

    IL.Value @value = ParseValue();
    yield return @value;

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (IL.Value v in ParseCallArgs()) {
      yield return v;
    }
  }

  private IEnumerable<IL.ID> ParseIdList() {
    IL.ID id = IdFromString(Eat(TokenType.ID, TokenType.GlobalID).Image);

    yield return id;

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (IL.ID i in ParseIdList()) {
      yield return i;
    }
  }

  private IL.Type TypeFromString(string str) {
    switch (str) {
      case "void": return IL.Type.Void;
      case "u8": return IL.Type.U8;
      case "u16": return IL.Type.U16;
      case "u32": return IL.Type.U32;
      case "u64": return IL.Type.U64;
      case "i8": return IL.Type.I8;
      case "i16": return IL.Type.I16;
      case "i32": return IL.Type.I32;
      case "i64": return IL.Type.I64;
      case "f32": return IL.Type.F32;
      case "f64": return IL.Type.F64;
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.ID IdFromString(string str) {
    if (str.StartsWith("@")) { // global
      return new IL.GlobalID(str.Remove(0, 1));
    }
    else if (str.StartsWith("$")) { // local
      return new IL.ID(str.Remove(0, 1));
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.GlobalID GlobalIdFromString(string str) {
    IL.ID id = IdFromString(str);
    if (id is IL.GlobalID) {
      return (IL.GlobalID)id;
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.Constant ConstantFromString(string str) {
    // find numeric and type in constant string
    Regex valRegex = new("([0-9.])([uif][0-9]{1,2})");
    Match m = valRegex.Match(str);
    if (m.Groups.Count < 3) {
      throw new Exception(); // TODO: nice exception
    }
    string valStr = m.Groups[1].Value;
    string typeStr = m.Groups[2].Value;

    IL.Type type = TypeFromString(typeStr);

    if (type.IsInteger()) {
      long @value;
      if (!long.TryParse(valStr, out @value)) {
        throw new Exception(); // TODO: nice exception
      }
      return new IL.Constant(type, @value);
    }
    else if (type.IsFloat()) {
      double @value;
      if (!double.TryParse(valStr, out @value)) {
        throw new Exception(); // TODO: nice exception
      }
      return new IL.Constant(type, @value);
    }

    throw new Exception(); // TODO: nice exception
  }

  private IL.BinaryOp BinOpFromToken(Token token,
                                     IL.Value left,
                                     IL.Value right) {
    IL.BinaryOp.Operator? op = token.Image switch {
      "+" => IL.BinaryOp.Operator.Add,
      "-" => IL.BinaryOp.Operator.Sub,
      "*" => IL.BinaryOp.Operator.Mul,
      "/" => IL.BinaryOp.Operator.Div,
      "==" => IL.BinaryOp.Operator.Eq,
      "!=" => IL.BinaryOp.Operator.Neq,
      "<" => IL.BinaryOp.Operator.Lt,
      ">" => IL.BinaryOp.Operator.Gt,
      "<=" => IL.BinaryOp.Operator.Leq,
      ">=" => IL.BinaryOp.Operator.Geq,
      "&&" => IL.BinaryOp.Operator.BoolAnd,
      "||" => IL.BinaryOp.Operator.BoolOr,
      "<<" => IL.BinaryOp.Operator.BitLs,
      ">>" => IL.BinaryOp.Operator.BitRs,
      "&" => IL.BinaryOp.Operator.BitAnd,
      "|" => IL.BinaryOp.Operator.BitOr,
      "^" => IL.BinaryOp.Operator.BitXor,
      _ => null,
    };

    if (op is null) {
      throw new Exception(); // TODO: nice exception
    }

    return new IL.BinaryOp((IL.BinaryOp.Operator)op, left, right);
  }

  private IL.UnaryOp UnOpFromToken(Token token, IL.Value @value) {
    IL.UnaryOp.Operator? op = token.Image switch {
      "-@" => IL.UnaryOp.Operator.Neg,
      "!@" => IL.UnaryOp.Operator.BoolNot,
      "~@" => IL.UnaryOp.Operator.BitNot,
      _ => null,
    };

    if (op is null) {
      throw new Exception(); // TODO: nice exception
    }

    return new IL.UnaryOp((IL.UnaryOp.Operator)op, @value);
  }
}
