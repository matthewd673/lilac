using Lilac.CodeGen.Targets.Wasm;

namespace Lilac.Tests.GraphTests.CodeGenTests.WasmTests;

public class LEB128Tests {
  [Fact]
  public void EncodeUnsigned624485() {
    byte[] bytes = LEB128.EncodeUnsigned(624_485);
    Assert.Equal([0xe5, 0x8e, 0x26], bytes); // LSB to MSB
  }

  [Fact]
  public void EncodeSignedNegative123456() {
    byte[] bytes = LEB128.EncodeSigned(-123_456);
    Assert.Equal([0xc0, 0xbb, 0x78], bytes);
  }

  [Fact]
  public void EncodeSignedEqualsEncodeUnsigned() {
    byte[] uBytes = LEB128.EncodeUnsigned(128);
    byte[] sBytes = LEB128.EncodeSigned(128);

    Assert.Equal([0x80, 0x01], uBytes);
    Assert.Equal(uBytes, sBytes);
  }
}