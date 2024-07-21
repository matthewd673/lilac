namespace Lilac.Frontend.SyntaxExceptions;

public abstract class SyntaxException : Exception {
  public SyntaxException(string name, Position position, string message)
    : base($"{name} at {position}:\n  {message}") {
    // Empty
  }
}

public class UnexpectedToken : SyntaxException {
  public UnexpectedToken(Position position, TokenType[] expected, Token actual)
    : base("Unexpected token", position,
           $"Expected {StringifyTokenTypes(expected)} but saw {actual}") {
    // Empty
  }

  protected static string StringifyTokenTypes(TokenType[] types) {
    string s = "";
    foreach (TokenType t in types) {
      s += $"{t.ToString()}, ";
    }

    if (s.Length > 2) {
      s = s.Remove(s.Length - 2);
    }

    return s;
  }
}