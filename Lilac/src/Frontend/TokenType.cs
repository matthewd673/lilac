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