using Lilac.IL;
using System.Text.RegularExpressions;
using Lilac.Frontend.SyntaxExceptions;
using Lilac.IL.Math;

namespace Lilac.Frontend;

public class Parser(string str)
{
  private readonly Scanner scanner = new(str);
  private Token nextToken = new(TokenType.None, "", new(0, 0));

  public static Program ParseFile(string filename) {
    string content = File.ReadAllText(filename);
    Parser parser = new(content);
    return parser.Parse();
  }

  public Program Parse() {
    nextToken = scanner.ScanNext();
    return ParseProgram();
  }

  private bool See(params TokenType[] types) => types.Contains(nextToken.Type);

  private Token Eat(params TokenType[] types) {
    if (!types.Contains(nextToken.Type)) {
      throw new UnexpectedTokenException(nextToken.Position, types, nextToken);
    }

    Token eaten = nextToken;
    nextToken = scanner.ScanNext();
    return eaten;
  }

  private bool TryEat(params TokenType[] types) =>
    See(types) && Eat(types) is not null;

  private Program ParseProgram() {
    Program program = new();

    // parse top level components
    while (!See(TokenType.EOF)) {
      // ignore newlines here
      if (TryEat(TokenType.NewLine)) {
        // Empty
      }
      // global def
      else if (See(TokenType.Global)) {
        program.Globals.Add(ParseGlobalDef());
      }
      // func def
      else if (See(TokenType.Func)) {
        program.FuncDefs.Add(ParseFuncDef());
      }
      // extern func def
      else if (See(TokenType.Extern)) {
        program.ExternFuncDefs.Add(ParseExternFuncDef());
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
    List<Statement> stmtList = [];

    // parse stmts until we reach the end
    while (!See(TokenType.EOF, TokenType.End, TokenType.Func)) {
      stmtList.AddRange(ParseStmt());
    }

    return stmtList;
  }

  private List<Statement> ParseStmt() {
    // empty stmt
    if (TryEat(TokenType.NewLine)) {
      return [];
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

      return [new Definition(type, id, rhs)];
    }
    // label
    else if (See(TokenType.Label)) {
      string labelStr = Eat(TokenType.Label).Image;
      labelStr = labelStr.Remove(labelStr.Length - 1); // remove ':'

      return [new Label(labelStr)];
    }
    // jump
    else if (TryEat(TokenType.Jump)) {
      return [new Jump(Eat(TokenType.Name).Image)];
    }
    // jump zero
    else if (TryEat(TokenType.JumpZero)) {
      Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return [new JumpZero(targetStr, @value)];
    }
    // jump not zero
    else if (TryEat(TokenType.JumpNotZero)) {
      Value @value = ParseValue();
      string targetStr = Eat(TokenType.Name).Image;

      return [new JumpNotZero(targetStr, @value)];
    }
    // return
    else if (TryEat(TokenType.Return)) {
      return [new Return(ParseValue())];
    }
    // void call
    else if (TryEat(TokenType.VoidConst)) {
      return [new VoidCall(ParseCall())];
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
    else if (TryEat(TokenType.Phi)) {
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
    if (TryEat(TokenType.Call)) {
      // eat func name
      string funcName = Eat(TokenType.Name).Image;

      // eat args
      Eat(TokenType.LeftParen);
      List<Value> args = ParseCallArgs().ToList();
      Eat(TokenType.RightParen);

      return new Call(funcName, args);
    }
    // extern func call
    else if (TryEat(TokenType.Extern)) {
      // eat func source and name
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
    else if (TryEat(TokenType.VoidConst)) {
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
    if (!TryEat(TokenType.Comma)) {
      yield break;
    }

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
    if (!TryEat(TokenType.Comma)) {
      yield break;
    }

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
    if (!TryEat(TokenType.Comma)) {
      yield break;
    }

    foreach (Value v in ParseCallArgs()) {
      yield return v;
    }
  }

  private IEnumerable<ID> ParseIdList() {
    if (See(TokenType.RightParen)) {
      yield break;
    }

    ID id = IdFromString(Eat(TokenType.ID, TokenType.GlobalID).Image);
    yield return id;

    // if we see a comma then we have to recurse
    if (!TryEat(TokenType.Comma)) {
      yield break;
    }

    foreach (ID i in ParseIdList()) {
      yield return i;
    }
  }

  private IL.Type TypeFromString(string str) => str switch {
    "void" => IL.Type.Void,
    "u8" => IL.Type.U8,
    "u16" => IL.Type.U16,
    "u32" => IL.Type.U32,
    "u64" => IL.Type.U64,
    "i8" => IL.Type.I8,
    "i16" => IL.Type.I16,
    "i32" => IL.Type.I32,
    "i64" => IL.Type.I64,
    "f32" => IL.Type.F32,
    "f64" => IL.Type.F64,
    // NOTE: If this happens then something is wrong in the Scanner
    _ => throw new InvalidTypeException(nextToken.Position, str),
  };

  private ID IdFromString(string str) => str[0] switch {
    '@' => new GlobalID(str.Remove(0, 1)),
    '$' => new LocalID(str.Remove(0, 1)),
    _ => throw new InvalidStringFormatException(nextToken.Position, str, "ID"),
  };

  private LocalID LocalIdFromString(string str) =>
    IdFromString(str) is LocalID lId
      ? lId
      : throw new InvalidStringFormatException(nextToken.Position, str, "LocalID");

  private GlobalID GlobalIdFromString(string str) =>
    IdFromString(str) is GlobalID gId
      ? gId
      : throw new InvalidStringFormatException(nextToken.Position, str, "GlobalID");

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

  private BinaryOp BinOpFromToken(Token token, Value left, Value right) {
    BinaryOp.Operator op = token.Image switch {
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
      _ => throw new InvalidStringFormatException(nextToken.Position, token.Image,
                                                  "binary operator"),

    };

    return new BinaryOp(op, left, right);
  }

  private UnaryOp UnOpFromToken(Token token, Value @value) {
    UnaryOp.Operator op = token.Image switch {
      "-@" => UnaryOp.Operator.Neg,
      "!@" => UnaryOp.Operator.BoolNot,
      "~@" => UnaryOp.Operator.BitNot,
      _ => throw new InvalidStringFormatException(nextToken.Position, token.Image,
                                                  "unary operator"),

    };

    return new UnaryOp(op, @value);
  }
}
