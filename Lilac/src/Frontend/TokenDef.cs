using System.Text.RegularExpressions;

namespace Lilac.Frontend;

internal class TokenDef(TokenType type, Regex pattern) {
  public TokenType Type { get; } = type;
  public Regex Pattern { get; } = pattern;
}

