using Lilac.CodeGen.Targets.Wasm;

namespace Lilac.Tests.CodeGenTests.WasmTests;

public class HexWriterTests {
  [Theory]
  [InlineData(new byte[] { 0x01, 0x02, 0xff, 0xfd })]
  [InlineData(new byte[] {})]
  public void WriteSingleSequence(byte[] sequence) {
    HexWriter hw = new();
    hw.Write(sequence);
    Assert.Equal(sequence, [..hw]);
  }

  [Theory]
  [InlineData("lilac", new byte[] { 0x6c, 0x69, 0x6c, 0x61, 0x63 })]
  [InlineData("", new byte[] {})]
  public void WriteAscii(string text, byte[] expected) {
    HexWriter hw = new();
    hw.WriteAscii(text);
    Assert.Equal(expected, [..hw]);
  }

  [Theory]
  [InlineData("li", "lac", new byte[] { 0x6c, 0x69, 0x6c, 0x61, 0x63 })]
  [InlineData("", "", new byte[] {})]
  public void WriteMultipleSequences(string asciiOne,
                                     string asciiTwo,
                                     byte[] expected) {
    HexWriter hw = new();
    hw.WriteAscii(asciiOne);
    hw.WriteAscii(asciiTwo);
    Assert.Equal(expected, [..hw]);
  }

  [Theory]
  [InlineData("lilacε", new byte[] { 0x6c, 0x69, 0x6c, 0x61, 0x63, 0xce, 0xb5})]
  [InlineData("", new byte[] {})]
  public void WriteUnicode(string text, byte[] expected) {
    HexWriter hw = new();
    hw.WriteUtf8(text);
    Assert.Equal(expected, [..hw]);
  }
}
