using System.Text.RegularExpressions;
using Lilac.Frontend.SyntaxExceptions;

namespace Lilac.Frontend;

internal class Scanner {
  private string str;
  private int scanRow;
  private int scanCol;

  public Scanner(string str) {
    this.str = str;
    scanRow = 0;
    scanCol = 0;
  }

  public Token ScanNext() {
    // strip whitespace
    bool sawNl = StripWhitespace();
    Position pos = new(scanRow, scanCol);

    // return newline if it was stripped
    // newlines denote end of statement so they are meaningful
    if (sawNl) {
      return new(TokenType.NewLine, "\n", pos);
    }

    // return end of file once we reach it
    if (str.Length == 0) {
      return new(TokenType.EOF, "$$", pos);
    }

    // find best possible token match from defs list
    Token? best = null;
    foreach (TokenDef t in TokenDefConstants.DefList) {
      // find first match
      Match m = t.Pattern.Match(str);

      // skip if no match or match is not at beginning of string
      if (!m.Success || m.Index > 0) {
        continue;
      }

      // something is always better than nothing
      if (best is null) {
        best = new(t.Type, m.Value, pos);
        continue;
      }

      // check if this is better than the current best (longer is better)
      if (m.Length > best.Image.Length) {
        best = new(t.Type, m.Value, pos);
      }
    }

    if (best is null) {
      throw new InvalidCharacterException(pos, str[0]);
    }

    // trim best match from string and return
    str = str.Remove(0, best.Image.Length);
    scanCol += best.Image.Length;

    return best;
  }

  private bool StripWhitespace() {
    bool sawNl = false;

    while (true) {
      if (str.StartsWith(" ")) {
        str = str.Remove(0, 1);
        scanCol += 1;
      }
      else if (str.StartsWith("\n")) {
        str = str.Remove(0, 1);
        scanRow += 1;
        scanCol = 0;
        sawNl = true;
      }
      else if (str.StartsWith("\r")) {
        str = str.Remove(0, 1);
      }
      else if (str.StartsWith("\t")) {
        str = str.Remove(0, 1);
        scanCol += 1;
      }
      // ignore annotations
      else if (str.StartsWith("\"")) {
        while (str.Length > 0 && str[0] != '\n') {
          str = str.Remove(0, 1);
        }
      }
      else {
        break;
      }
    }

    return sawNl;
  }
}
