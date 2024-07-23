namespace Lilac.Frontend.SyntaxExceptions;

public abstract class SyntaxException : Exception {
  public SyntaxException(string name, Position position, string message)
    : base($"{name} at {position}\n  {message}") {
    // Empty
  }
}

public class UnexpectedTokenException : SyntaxException {
  public UnexpectedTokenException(Position position, TokenType[] expected,
                                  Token actual)
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

public class InvalidCharacterException : SyntaxException {
  public InvalidCharacterException(Position position, char character)
    : base("Invalid character", position,
           $"Saw invalid character '{character}' while scanning") {
    // Empty
  }
}

public class CannotBeginException : SyntaxException {
  public CannotBeginException(Position position, string production,
                              Token token)
    : base("Cannot begin", position,
           $"Production \"{production}\" cannot begin with {token}") {
    // Empty
  }
}

public class InvalidTypeException : SyntaxException {
  public InvalidTypeException(Position position, string type)
    : base("Invalid type", position,
           $"Saw invalid type \"{type}\" while parsing") {
    // Empty
  }
}

public class InvalidStringFormatException : SyntaxException {
  public InvalidStringFormatException(Position position, string str,
                                      string expected)
    : base("Invalid string format", position,
           $"Cannot parse string \"{str}\" into format \"{expected}\"") {
    // Empty
  }
}