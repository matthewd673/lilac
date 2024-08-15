using System.Buffers.Binary;

namespace Lilac.IL.Math;

public static class ValueEncoder {
  public static byte[] Encode(Type type, object value) {
    byte[] arr = new byte[type.GetSizeBytes()];

    switch (type) {
      case Type.U8:
        arr[0] = Convert.ToByte(value);
        break;
      case Type.I8:
        arr[0] = (byte)Convert.ToSByte(value);
        break;
      case Type.U16:
        BinaryPrimitives.WriteUInt16LittleEndian(arr,
                                                 Convert.ToUInt16(value));
        break;
      case Type.I16:
        BinaryPrimitives.WriteInt16LittleEndian(arr,
                                                Convert.ToInt16(value));
        break;
      case Type.U32:
        BinaryPrimitives.WriteUInt32LittleEndian(arr,
                                                 Convert.ToUInt32(value));
        break;
      case Type.I32:
        BinaryPrimitives.WriteInt32LittleEndian(arr,
                                                Convert.ToInt32(value));
        break;
      case Type.U64:
        BinaryPrimitives.WriteUInt64LittleEndian(arr,
                                                 Convert.ToUInt64(value));
        break;
      case Type.I64:
        BinaryPrimitives.WriteInt64LittleEndian(arr,
                                                Convert.ToInt64(value));
        break;
      case Type.F32:
        BinaryPrimitives.WriteSingleLittleEndian(arr,
                                                 Convert.ToSingle(value));
        break;
      case Type.F64:
        BinaryPrimitives.WriteDoubleLittleEndian(arr,
                                              Convert.ToDouble(value));
        break;
      case Type.Void:
        // Do nothing, a Void is a zero-length array
        break;
      default:
        throw new ArgumentOutOfRangeException();
    }

    return arr;
  }
}