using System.Buffers.Binary;

namespace Lilac.IL.Math;

public static class ValueEncoder {
  public static byte[] Encode(Type type, object value) {
    byte[] arr = new byte[type.GetSizeBytes()];

    switch (type) {
      case Type.U8:
        arr[0] = (byte)value;
        break;
      case Type.I8:
        arr[0] = (byte)(sbyte)value;
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(arr, (ushort)value);
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(arr, (short)value);
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(arr, (uint)value);
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(arr, (int)value);
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(arr, (ulong)value);
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(arr, (long)value);
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(arr, (float)value);
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleBigEndian(arr, (double)value);
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return arr;
  }
}