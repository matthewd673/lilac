using Lilac.CodeGen.Targets.Wasm;

namespace Lilac.Tests.CodeGenTests.WasmTests;

public class LEB128Tests {
  [Theory]
  [InlineData(624_485, new byte[] { 0xe5, 0x8e, 0x26 })]
  public void EncodeUnsigned(int value, byte[] expected) {
    byte[] bytes = LEB128.EncodeUnsigned(value);
    Assert.Equal(expected, bytes);
  }

  [Theory]
  [InlineData(-123_456, new byte[] { 0xc0, 0xbb, 0x78 })]
  public void EncodeSigned(int value, byte[] expected) {
    byte[] bytes = LEB128.EncodeSigned(value);
    Assert.Equal(expected, bytes);
  }

  [Theory]
  [InlineData(128)]
  [InlineData(123_456)]
  [InlineData(0)]
  [InlineData(810)]
  public void EncodeSignedEqualsEncodeUnsignedForPositiveValues(int value) {
    byte[] uBytes = LEB128.EncodeUnsigned(value);
    byte[] sBytes = LEB128.EncodeSigned(value);

    Assert.Equal(uBytes, sBytes);
  }
}
