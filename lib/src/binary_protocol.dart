
import 'dart:typed_data';

import 'package:buffer/buffer.dart';

abstract class BinaryProtocol {
  // static const DEF_BUF_SIZE = 256;

  Uint8List get bytes {
    var buf = ByteDataWriter();
    pack(buf);

    return buf.toBytes();
  }

  void parse(Uint8List bs) {
    var buf = ByteDataReader();
    buf.add(bs);

    unpack(buf);
  }

  void pack(ByteDataWriter buf);
  void unpack(ByteDataReader buf);

  moreString() { return ''; }
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