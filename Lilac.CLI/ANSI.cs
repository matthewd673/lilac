namespace Lilac.CLI;

public static class ANSI {
  public enum Color {
    Default = 39,
    Black = 30,
    Red = 31,
    Green = 32,
    Yellow = 33,
    Blue = 34,
    Magenta = 35,
    Cyan = 36,
    White = 37,

    BlackBright = 90,
    RedBright = 91,
    GreenBright = 92,
    YellowBright = 93,
    BlueBright = 94,
    MagentaBright = 95,
    CyanBright = 96,
    WhiteBright = 97,
  }

  private const int Lilac256 = 147;

  public static string Format(object obj,
                              Color color = Color.Default,
                              bool bold = false) {
    return $"\x1b[{(int)color}m{(bold ? "\x1b[1m" : "")}{obj}\x1b[0m";
  }

  public static string Format256(object obj, int color, bool bold = false) {
    return $"\x1b[38;5;{color}m{(bold ? "\x1b[1m" : "")}{obj}\x1b[0m";
  }
}