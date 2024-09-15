using System.Text.RegularExpressions;
using Lilac.Frontend.SyntaxExceptions;

namespace Lilac.Frontend;

internal class Scanner(string str) {
  private string str = str;
  private int index = 0;
  private int scanRow = 0;
  private int scanCol = 0;

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
      Match match = t.Pattern.Match(str, index);

      // skip if no match or match is not at beginning of string
      if (!match.Success || match.Index > index) {
        continue;
      }

      // something is always better than nothing
      if (best is null) {
        best = new(t.Type, match.Value, pos);
        continue;
      }

      // check if this is better than the current best (longer is better)
      if (match.Length > best.Image.Length) {
        best = new(t.Type, match.Value, pos);
      }
    }

    if (best is null) {
      throw new InvalidCharacterException(pos, str[0]);
    }

    // trim best match from string and return
    index += best.Image.Length;
    scanCol += best.Image.Length;

    return best;
  }

  private bool StripWhitespace() {
    bool sawNl = false;

    bool stripping = true;
    while (stripping) {
      switch (str[index]) {
        case ' ':
          index += 1;
          scanCol += 1;
          break;
        case '\n':
          index += 1;
          scanRow += 1;
          scanCol = 0;
          sawNl = true;
          break;
        case '\r':
          index += 1;
          break;
        case '\t':
          index += 1;
          scanCol += 1;
          break;
        case '"':
          while (str.Length > 0 && str[0] != '\n') {
            index += 1;
          }
          break;
        default:
          stripping = false;
          break;
      }
    }

    return sawNl;
  }
}
