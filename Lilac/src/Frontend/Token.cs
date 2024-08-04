namespace Lilac.Frontend;

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

