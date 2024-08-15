using Lilac.IL.Math;
using Type = Lilac.IL.Type;

namespace Lilac.Tests.ILTests.MathTests;

public class ValueEncoderTests {
  [Theory]
  [InlineData(Type.U8, 0, new byte[] { 0 })]
  [InlineData(Type.U8, 255, new byte[] { 255 })]
  [InlineData(Type.U8, 67, new byte[] { 0x43 })]
  [InlineData(Type.I8, -128, new byte[] { 0x80 })]
  [InlineData(Type.I8, 127, new byte[] { 0x7F })]
  [InlineData(Type.I8, -96, new byte[] { 0xA0 })]
  [InlineData(Type.I8, 96, new byte[] { 0x60 })]
  [InlineData(Type.U16, 0, new byte[] { 0, 0 })]
  [InlineData(Type.U16, 65_535, new byte[] { 0xFF, 0xFF })]
  [InlineData(Type.I16, -32_768, new byte[] { 0x00, 0x80 })]
  [InlineData(Type.I16, 32_767, new byte[] { 0xFF, 0x7F })]
  [InlineData(Type.U32, 0, new byte[] { 0, 0, 0, 0 })]
  [InlineData(Type.U32, 4_294_967_295, new byte[] { 0xFF, 0xFF, 0xFF, 0xFF })]
  [InlineData(Type.I32, -2_147_483_648, new byte[] { 0x00, 0x00, 0x00, 0x80 })]
  [InlineData(Type.I32, 2_147_483_647, new byte[] { 0xFF, 0xFF, 0xFF, 0x7F })]
  [InlineData(Type.U64, 0, new byte[] { 0, 0, 0, 0, 0, 0, 0, 0 })]
  [InlineData(Type.U64, 18_446_744_073_709_551_615, new byte[] {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
  })]
  [InlineData(Type.I64, -9_223_372_036_854_775_808, new byte[] {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
  })]
  [InlineData(Type.I64, 9_223_372_036_854_775_807, new byte[] {
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F,
  })]
  [InlineData(Type.F32, 0, new byte[] { 0, 0, 0, 0 })]
  [InlineData(Type.F32, -0f, new byte[] { 0x00, 0x00, 0x00, 0x80 })]
  [InlineData(Type.F32, 105.06448f, new byte[] {
    0x04, 0x21, 0xD2, 0x42,
  })]
  [InlineData(Type.F32, -121.68948f, new byte[] {
    0x04, 0x61, 0xF3, 0xC2,
  })]
  [InlineData(Type.F64, 0, new byte[] { 0, 0, 0, 0, 0, 0, 0, 0 })]
  [InlineData(Type.F64, -0.0, new byte[] {
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x80,
  })]
  [InlineData(Type.F64, 223113.543236, new byte[] {
    0xB0, 0x1D, 0x8C, 0x58, 0x4C, 0x3C, 0x0B, 0x41,
  })]
  [InlineData(Type.F64, -1683113.3452894, new byte[] {
    0xD9, 0xE2, 0x64, 0x58, 0xA9, 0xAE, 0x39, 0xC1,
  })]
  public void EncodeValueInRange(Type type, object value, byte[] expected) {
    Assert.True(ValueEncoder.Encode(type, value).SequenceEqual(expected));
  }
}