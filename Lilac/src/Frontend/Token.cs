namespace Lilac.Frontend;

public class Token(TokenType type, string image, Position position) {
  public TokenType Type { get; } = type;
  public string Image { get; } = image;
  public Position Position { get; } = position;

  public override string ToString() =>
    $"{{ type: {Type}, image: \"{Image}\", position: {Position} }}";
}

