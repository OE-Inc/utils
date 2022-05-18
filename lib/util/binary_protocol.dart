
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:utils/util/utils.dart';

import 'log.dart';
import 'storage/annotation/sql.dart';

abstract class BinaryProtocol<T> extends SqlSerializable<Uint8List, T> {
  // static const DEF_BUF_SIZE = 256;

  Uint8List get bytes {
    var buf = ByteDataWriter();
    pack(buf);

    return buf.toBytes();
  }

  void parse(Uint8List bs, { bool allowNull = false, }) {
    if (bs == null && allowNull == true)
      return;

    var buf = ByteDataReader();
    buf.add(bs);

    unpack(buf);
  }

  void pack(ByteDataWriter buf);
  void unpack(ByteDataReader buf);

  moreString() { return ''; }

  @override
  String toString() {
    return "$runtimeType { ${moreString()} }";
  }

  @override
  T fromSave(Uint8List col) {
    try {
      return (this..parse(col)) as T;
    } catch (e) {
      Log.e("$runtimeType", () => 'fromSave failed(col: ${col.hex}), use default value, error: ', e);
      return this as T;
    }
  }

  @override
  Uint8List toSave() {
    return bytes;
  }

}

abstract class PositionedBinaryProtocol<T> extends BinaryProtocol<T> {
  int get position;
}


class EmptyBinaryProtocol extends BinaryProtocol {
  @override
  void pack(ByteDataWriter buf) { }

  @override
  void unpack(ByteDataReader buf) { }
}


extension ByteDataWriterExt on ByteDataWriter {

  void writeProtocol(BinaryProtocol p) {
    if (p != null)
      write(p.bytes);
  }

}


extension ByteDataReaderExt on ByteDataReader {

  void readProtocol(BinaryProtocol p) {
    if (p != null)
      p.unpack(this);
  }

}