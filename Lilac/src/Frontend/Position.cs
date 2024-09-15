namespace Lilac.Frontend;

public class Position(int row, int col) {
  public int Row { get; } = row;
  public int Col { get; } = col;

  public override string ToString() => $"{Row + 1}:{Col + 1}";
}

