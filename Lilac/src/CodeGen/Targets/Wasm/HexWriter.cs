using System.Collections;
using System.Text;

namespace Lilac.CodeGen.Targets.Wasm;

public class HexWriter : IEnumerable<byte> {
  private List<byte> bytes = [];

  public int Count => bytes.Count;

  public void Write(params byte[] byteArr) {
    bytes.AddRange(byteArr);
  }

  public void Write(List<byte> byteList) {
    bytes.AddRange(byteList);
  }

  public void WriteAscii(string str) {
    bytes.AddRange(Encoding.ASCII.GetBytes(str));
  }

  public void WriteUtf8(string str) {
    bytes.AddRange(Encoding.UTF8.GetBytes(str));
  }

  public void WriteFrom(HexWriter other) {
    bytes.AddRange(other);
  }

  public IEnumerator<byte> GetEnumerator() {
    return bytes.GetEnumerator();
  }

  IEnumerator IEnumerable.GetEnumerator() {
    return GetEnumerator();
  }

  public override string ToString() {
    return Encoding.Default.GetString(bytes.ToArray());
  }
}
