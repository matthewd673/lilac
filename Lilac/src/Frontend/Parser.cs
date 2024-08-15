using Lilac.IL;
using System.Text.RegularExpressions;
using Lilac.Frontend.SyntaxExceptions;
using Lilac.IL.Math;

namespace Lilac.Frontend;

public class Parser {
  private Scanner scanner;
  private Token nextToken;

  public static Program ParseFile(string filename) {
    string content = File.ReadAllText(filename);
    Parser parser = new(content);
    return parser.Parse();
  }

  public Parser(string str) {
    scanner = new(str);
    nextToken = new(TokenType.None, "", new(0, 0));
  }

  public Program Parse() {
    nextToken = scanner.ScanNext();
    return ParseProgram();
  }

  public List<Statement> ParseStatement() {
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

    throw new UnexpectedTokenException(nextToken.Position, types, nextToken);
  }

  private Program ParseProgram() {
    Program program = new();

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
        throw new CannotBeginException(nextToken.Position, "program",
                                       nextToken);
      }
    }

    Eat(TokenType.EOF);

    return program;
  }

  private List<Statement> ParseStmtList() {
    List<Statement> stmtList = new();

    // parse stmts until we reach the end
    while (!See(TokenType.EOF, TokenType.End, TokenType.Func)) {
      stmtList.AddRange(ParseStmt());
    }

    return stmtList;
  }

  private List<Statement> ParseStmt() {
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
      ID id = IdFromString(idStr);

      Eat(TokenType.Assignment);

      Expression rhs = ParseExpr();

      return new() { new Definition(type, id, rhs) };
    }
    // label
    else if (See(TokenType.Label)) {
      string labelStr = Eat(TokenType.Label).Image;
      labelStr = labelStr.Remove(labelStr.Length - 1); // remove ':'

      return new() { new Label(labelStr) };
    }
    // jump
    else if (See(TokenType.Jump)) {
      Eat(TokenType.Jump);
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new Jump(targetStr) };
    }
    // jump zero
    else if (See(TokenType.JumpZero)) {
      Eat(TokenType.JumpZero);
      Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new JumpZero(targetStr, @value) };
    }
    // jump not zero
    else if (See(TokenType.JumpNotZero)) {
      Eat(TokenType.JumpNotZero);
      Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return new() { new JumpNotZero(targetStr, @value) };
    }
    // return
    else if (See(TokenType.Return)) {
      Eat(TokenType.Return);
      Value @value = ParseValue();

      return new() { new Return(@value) };
    }
    // void call
    else if (See(TokenType.VoidConst)) {
      Eat(TokenType.VoidConst);
      Call call = ParseCall();

      return new() { new VoidCall(call) };
    }

    throw new CannotBeginException(nextToken.Position, "stmt",
                                   nextToken);
  }

  private Expression ParseExpr() {
    // value or binary op
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst,
            TokenType.ID, TokenType.GlobalID)) {
      Value lVal = ParseValue();

      // if see a binary op, parse that
      // otherwise, we're done
      if (!See(TokenType.BinaryOp)) {
        return new ValueExpr(lVal);
      }

      Token binopTok = Eat(TokenType.BinaryOp);
      Value rVal = ParseValue();

      return BinOpFromToken(binopTok, lVal, rVal);
    }
    // unary op
    else if (See(TokenType.UnaryOp)) {
      Token unopTok = Eat(TokenType.UnaryOp);
      Value @value = ParseValue();

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
      List<ID> ids = ParseIdList().ToList();
      Eat(TokenType.RightParen);

      return new Phi(ids);
    }

    throw new CannotBeginException(nextToken.Position, "expr",
                                   nextToken);
  }

  private Call ParseCall() {
    // func call
    if (See(TokenType.Call)) {
      // eat func name
      Eat(TokenType.Call);
      string funcName = Eat(TokenType.Name).Image;

      // eat args
      Eat(TokenType.LeftParen);
      List<Value> args = ParseCallArgs().ToList();
      Eat(TokenType.RightParen);

      return new Call(funcName, args);
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
      List<Value> args = ParseCallArgs().ToList();
      Eat(TokenType.RightParen);

      return new ExternCall(funcSource, funcName, args);
    }

    throw new CannotBeginException(nextToken.Position, "call",
                                   nextToken);
  }

  private Value ParseValue() {
    // constant
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst)) {
      return ParseConstant();
    }
    // void constant
    else if (See(TokenType.VoidConst)) {
      Eat(TokenType.VoidConst);
      return new Constant(IL.Type.Void, []);
    }
    // id
    else if (See(TokenType.ID, TokenType.GlobalID)) {
      string idStr = Eat(TokenType.ID, TokenType.GlobalID).Image;
      return IdFromString(idStr);
    }

    throw new CannotBeginException(nextToken.Position, "value",
                                   nextToken);
  }

  private Constant ParseConstant() {
    if (See(TokenType.UIntConst, TokenType.IntConst, TokenType.FloatConst)) {
      string constStr = Eat(TokenType.UIntConst, TokenType.IntConst,
                            TokenType.FloatConst).Image;
      return ConstantFromString(constStr);
    }

    throw new CannotBeginException(nextToken.Position, "constant",
                                   nextToken);
  }

  private GlobalDef ParseGlobalDef() {
    Eat(TokenType.Global);

    string typeStr = Eat(TokenType.Type).Image;
    IL.Type type = TypeFromString(typeStr);

    string idStr = Eat(TokenType.GlobalID).Image;
    GlobalID id = GlobalIdFromString(idStr);

    Eat(TokenType.Assignment);

    Constant rhs = ParseConstant(); // rhs of GlobalDef is always a Constant

    return new GlobalDef(type, id, rhs);
  }

  private FuncDef ParseFuncDef() {
    Eat(TokenType.Func);
    string name = Eat(TokenType.Name).Image;

    Eat(TokenType.LeftParen);
    List<FuncParam> funcParams = ParseFuncParams().ToList();
    Eat(TokenType.RightParen);

    Eat(TokenType.Arrow);
    string retTypeStr = Eat(TokenType.Type, TokenType.VoidConst).Image;
    IL.Type retType = TypeFromString(retTypeStr);
    Eat(TokenType.NewLine);

    List<Statement> stmtList = ParseStmtList();

    Eat(TokenType.End);

    return new FuncDef(name, funcParams, retType, stmtList);
  }

  private ExternFuncDef ParseExternFuncDef() {
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

    return new ExternFuncDef(source, name, funcParamTypes, retType);
  }

  private IEnumerable<FuncParam> ParseFuncParams() {
    // epsilon
    if (See(TokenType.RightParen)) {
      yield break;
    }

    string typeStr = Eat(TokenType.Type).Image;
    IL.Type type = TypeFromString(typeStr);

    string idStr = Eat(TokenType.ID).Image;
    LocalID id = LocalIdFromString(idStr);

    yield return new FuncParam(type, id);

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (FuncParam p in ParseFuncParams()) {
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

  private IEnumerable<Value> ParseCallArgs() {
    // epsilon
    if (See(TokenType.RightParen)) {
      yield break;
    }

    Value @value = ParseValue();
    yield return @value;

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (Value v in ParseCallArgs()) {
      yield return v;
    }
  }

  private IEnumerable<ID> ParseIdList() {
    ID id = IdFromString(Eat(TokenType.ID, TokenType.GlobalID).Image);

    yield return id;

    // if we see a comma then we have to recurse
    if (!See(TokenType.Comma)) {
      yield break;
    }

    Eat(TokenType.Comma);
    foreach (ID i in ParseIdList()) {
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

    // NOTE: if this happens then something is wrong in the Scanner
    throw new InvalidTypeException(nextToken.Position, str);
  }

  private ID IdFromString(string str) {
    if (str.StartsWith("@")) { // global
      return new GlobalID(str.Remove(0, 1));
    }
    else if (str.StartsWith("$")) { // local
      return new LocalID(str.Remove(0, 1));
    }

    throw new InvalidStringFormatException(nextToken.Position, str,
                                           "ID");
  }

  private LocalID LocalIdFromString(string str) {
    ID id = IdFromString(str);
    if (id is LocalID lId) {
      return lId;
    }

    throw new InvalidStringFormatException(nextToken.Position, str,
                                           "LocalID");
  }

  private GlobalID GlobalIdFromString(string str) {
    ID id = IdFromString(str);
    if (id is GlobalID gId) {
      return gId;
    }

    throw new InvalidStringFormatException(nextToken.Position, str,
                                           "GlobalID");
  }

  private Constant ConstantFromString(string str) {
    // find numeric and type in constant string
    Regex valRegex = new(@"(-?[0-9]*\.?[0-9]*)([uif][0-9]{1,2})");
    Match m = valRegex.Match(str);
    if (m.Groups.Count < 3) {
      throw new InvalidStringFormatException(nextToken.Position, str,
                                             "Constant");
    }

    string valStr = m.Groups[1].Value;
    string typeStr = m.Groups[2].Value;

    IL.Type type = TypeFromString(typeStr);

    if (type.IsInteger()) {
      if (!long.TryParse(valStr, out long value)) {
        throw new InvalidStringFormatException(nextToken.Position, valStr,
                                               "integer");
      }
      return new Constant(type, ValueEncoder.Encode(type, value));
    }
    else if (type.IsFloat()) {
      if (!double.TryParse(valStr, out double value)) {
        throw new InvalidStringFormatException(nextToken.Position, valStr,
                                               "float");
      }
      return new Constant(type, ValueEncoder.Encode(type, value));
    }

    throw new InvalidStringFormatException(nextToken.Position, valStr,
                                           "Constant");
  }

  private BinaryOp BinOpFromToken(Token token,
                                     Value left,
                                     Value right) {
    BinaryOp.Operator? op = token.Image switch {
      "+" => BinaryOp.Operator.Add,
      "-" => BinaryOp.Operator.Sub,
      "*" => BinaryOp.Operator.Mul,
      "/" => BinaryOp.Operator.Div,
      "%" => BinaryOp.Operator.Mod,
      "==" => BinaryOp.Operator.Eq,
      "!=" => BinaryOp.Operator.Neq,
      "<" => BinaryOp.Operator.Lt,
      ">" => BinaryOp.Operator.Gt,
      "<=" => BinaryOp.Operator.Leq,
      ">=" => BinaryOp.Operator.Geq,
      "&&" => BinaryOp.Operator.BoolAnd,
      "||" => BinaryOp.Operator.BoolOr,
      "<<" => BinaryOp.Operator.BitLs,
      ">>" => BinaryOp.Operator.BitRs,
      "&" => BinaryOp.Operator.BitAnd,
      "|" => BinaryOp.Operator.BitOr,
      "^" => BinaryOp.Operator.BitXor,
      _ => null,
    };

    if (op is null) {
      // NOTE: if we hit this then the TokenDef or the switch statement is wrong
      throw new InvalidStringFormatException(nextToken.Position, token.Image,
                                             "binary operator");
    }

    return new BinaryOp((BinaryOp.Operator)op, left, right);
  }

  private UnaryOp UnOpFromToken(Token token, Value @value) {
    UnaryOp.Operator? op = token.Image switch {
      "-@" => UnaryOp.Operator.Neg,
      "!@" => UnaryOp.Operator.BoolNot,
      "~@" => UnaryOp.Operator.BitNot,
      _ => null,
    };

    if (op is null) {
      // NOTE: if we hit this then the TokenDef or the switch statement is wrong
      throw new InvalidStringFormatException(nextToken.Position, token.Image,
                                             "unary operator");
    }

    return new UnaryOp((UnaryOp.Operator)op, @value);
  }
}
