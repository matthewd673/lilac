using System.Text.RegularExpressions;

namespace Lilac.Frontend;

internal class TokenDef {
  public TokenType Type { get; }
  public Regex Pattern { get; }

  public TokenDef(TokenType type, Regex pattern) {
    Type = type;
Pattern = pattern;
  }
}

