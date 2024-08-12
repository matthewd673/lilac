namespace Lilac.CodeGen.Targets.Wasm;

internal static class LEB128 {
  public static byte[] EncodeUnsigned(long number) {
    // NOTE: adapted from https://en.wikipedia.org/wiki/LEB128#C-like_pseudocode
    List<byte> bytes = [];
    while (true) {
      byte nextByte = (byte)(number & 0x7f);
      number >>= 7;

      // set highest-order bit if more bytes to come
      if (number != 0) {
        nextByte |= 0x80;
      }

      bytes.Add(nextByte);

      if (number == 0) {
        break;
      }
    }

    return bytes.ToArray();
  }

  public static byte[] EncodeSigned(long number) {
    // NOTE: adapted from https://en.wikipedia.org/wiki/LEB128#C-like_pseudocode
    bool negative = number < 0;

    // TODO: only supports 32 or 64 bit integers
    int size = number <= int.MaxValue && number >= int.MinValue ? 32 : 64;

    List<byte> bytes = [];
    while (true) {
      byte nextByte = (byte)(number & 0x7f);
      number >>= 7;

      // manually sign extend
      if (negative) {
        number |= ~0 << (size - 7);
      }

      if ((number == 0 && (nextByte & 0x40) == 0) ||
          (number == -1 && (nextByte & 0x40) != 0)) {
        bytes.Add(nextByte);
        break;
      }

      bytes.Add((byte)(nextByte | 0x80));
    }

    return bytes.ToArray();
  }
}