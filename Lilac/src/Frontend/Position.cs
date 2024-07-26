namespace Lilac.Frontend;

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

