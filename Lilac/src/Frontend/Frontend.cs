using System.Text.RegularExpressions;

namespace Lilac.Frontend;

public enum TokenType {
  None,

  Type,
  UIntConst,
  IntConst,
  FloatConst,
  VoidConst,
  BinaryOp,
  UnaryOp,
  Phi,
  Assignment,
  Label,
  Jump,
  JumpZero,
  JumpNotZero,
  Return,
  Func,
  ID,
  GlobalID,
  Name,
  End,
  LeftParen,
  RightParen,
  Arrow,
  Call,
  Comma,
  Extern,
  Global,

  NewLine,
  EOF,
}

class TokenDef {
  public TokenType Type { get; }
  public Regex Pattern { get; }

  public TokenDef(TokenType type, Regex pattern) {
    Type = type;
Pattern = pattern;
  }
}

public class Position {
  public int Row { get; }
  public int Col { get; }

  public Position(int row, int col) {
    Row = row;
    Col = col;
  }

  public override string ToString() {
    return $"{Row + 1}:{Col + 1}";
  }
}

public class Token {
  public TokenType Type { get; }
  public string Image { get; }
  public Position Position { get; }

  public Token(TokenType type, string image, Position position) {
    Type = type;
    Image = image;
    Position = position;
  }

  public override string ToString() {
    return $"{{ type: {Type}, image: \"{Image}\", position: {Position} }}";
  }
}

static class TokenDefConstants {
  public static TokenDef[] DefList = new TokenDef[] {
    // keywords
    new(TokenType.Type, new("u8|u16|u32|u64|i8|i16|i32|i64|f32|f64")),
    new(TokenType.Arrow, new("->")),
    new(TokenType.UnaryOp, new("-@|!@|~@")),
    new(TokenType.BinaryOp,
        new(@"\+|-|\*|\/|%|==|!=|<=|>=|<<|>>|&&|\|\||<|>|&|\||\^")),
    new(TokenType.Phi, new("phi")),
    new(TokenType.Assignment, new("=")),
    new(TokenType.Jump, new("jmp")),
    new(TokenType.JumpZero, new("jz")),
    new(TokenType.JumpNotZero, new("jnz")),
    new(TokenType.Return, new("ret")),
    new(TokenType.Func, new("func")),
    new(TokenType.End, new("end")),
    new(TokenType.LeftParen, new(@"\(")),
    new(TokenType.RightParen, new(@"\)")),
    new(TokenType.Call, new("call")),
    new(TokenType.Comma, new(",")),
    new(TokenType.Extern, new("extern")),
    new(TokenType.Global, new("global")),

    // other
    new(TokenType.VoidConst, new("void")),
    new(TokenType.UIntConst, new("([0-9]+)(u8|u16|u32|u64)")),
    new(TokenType.IntConst, new("(-?[0-9]+)(i8|i16|i32|i64)")),
    new(TokenType.FloatConst,
        new(@"-?(([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+))(f32|f64)")),
    // NOTE: there are no restrictions on these names when constructing IL
    // programatically, but these are reasonable restrictions for parsing.
    new(TokenType.Label, new(@"[\w!@$^&\[\];'.?<>]+:")),
    new(TokenType.ID, new(@"\$[a-zA-Z0-9_.]+")),
    new(TokenType.GlobalID, new("@[a-zA-Z0-9_.]+")),
    new(TokenType.Name, new("[a-zA-Z_.][a-zA-Z_.0-9]*")),
  };
}
