import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:hex/hex.dart';
import 'package:utils/src/simple_interface.dart';
import 'package:utils/src/unit.dart';
import 'error.dart';
import 'package:uuid/uuid.dart';

export 'bus.dart';
export 'error.dart';

export 'package:meta/meta.dart';

/// only used for IDE auto import helper.
@deprecated
class Utils { }

extension IntUtils on int {

  Uint8List toBytes(int size) {
    ByteDataWriter bdw = ByteDataWriter();
    if (size == 1 || size == 2 || size == 4 || size == 8) {
      bdw.writeInt(size, this);
      return bdw.toBytes();
    } else {
      bdw.writeInt(8, this);
      return bdw.toBytes().sublist(8 - size);
    }
  }

  static const _zeroStr = "0000000000000000000000000000000000000000000000000000000000000000";

  /// width is half-byte width, not full-byte width.
  String hexString({ bool withOx = true, int width = -1, }) {
    return radixString(leading: withOx, width: width, radix: 16);
  }

  /// width is bit width, not byte width, 0x10 => 0b10000
  String bitString({ bool withOb = true, int width = -1, }) {
    return radixString(leading: withOb, width: width, radix: 2);
  }

  /// width is the code unit width, not byte width
  String radixString({ bool leading = true, int width = -1, int radix = 16, }) {
    if (this == null)
      return null;

    var str = this.toRadixString(radix);

    if (width > str.length && (width - str.length) < _zeroStr.length)
      str = _zeroStr.substring(0, width - str.length) + str;

    var lStr;
    if (leading) {
      switch (radix) {
        case 2: lStr = '0b'; break;
        case 16: lStr = '0x'; break;
        default: lStr = '[Radix $radix]'; break;
      }
    }

    return leading ? "$lStr$str" : str;
  }

  static const MAX_BITS = 64;
  /// returns the max bit1 offset.
  int get maxBit1 {
    if (this == 0)
      return 0;

    int bit;
    for (int idx = 0; idx < MAX_BITS; ++idx) {
      bit = (this >> (MAX_BITS - idx - 1)) & 0x1;
      if (bit == 0)
        continue;

      print('max bit index: $idx');
      return MAX_BITS - idx;
    }

    return 0;
  }

  /// size = bit size, not byte size.
  /// returned bits are reserved(for bit stream) like: 0b10011 => [1, 0, 0, 1, 1]
  Uint8List bits([int bitSize]) {

    int bit;
    if (bitSize != null) {
      assert(bitSize >= 0 && bitSize <= MAX_BITS);
    } else {
      bitSize = maxBit1;
    }

    Uint8List bits = Uint8List(bitSize);

    for (int idx = 0; idx < bitSize; ++idx) {
      bit = (this >> idx) & 0x1;
      bits[bitSize - idx - 1] = bit;
    }

    return bits != null ? bits.bytes : Uint8List(0);
  }


  bool toBool([bool strict = true]) {
    if (strict && this != 0 && this != 1)
      throw IllegalArgumentException("toBool cannot process a int value not inside: [0, 1].");

    return this == 1;
  }

}

extension ByteUtils on Uint8List {

  Iterable<Uint8List> split(int sliceSize) sync* {
    int offs = 0;

    while (offs < length) {
      int len = min(sliceSize, length - offs);

      yield sublist(offs, offs + len);
      offs += len;
    }
  }

  int toInt(){
    var bytes = this;

    if(bytes == null || bytes.isEmpty || bytes.length > 8) {
      throw Exception("bytes length must be > 0 & < 8");
    }
    var length = bytes.length;
    int value = 0;
    for(int i = 0; i < length; i++) {
      value |= bytes[i] << ((length - i - 1) * 8);
    }
    return value;
  }

  void copyTo(Uint8List dest, int destOffset, [int len]) {
    len = len ?? length;

    for (int idx = 0; idx < len; ++idx)
      dest[destOffset + idx] = this[idx];
  }

  /// returns this, no copy.
  Uint8List xor(Uint8List xorIn, [ int thisOffset = 0, int length ]) {
    length = length ?? xorIn.length;
    
    for (int idx = 0; idx < length; ++idx)
      this[thisOffset + idx] ^= xorIn[idx];

    return this;
  }

  Uint8List copy([int start, int end]) {
    return sublist(start ?? 0, end);
  }

  bool equals(other) {
    if (other is! Uint8List)
      return false;

    if (other.length != length)
      return false;

    for (var idx = 0; idx < length; ++idx) {
      if (other[idx] != this[idx])
        return false;
    }

    return true;
  }

  String hexString({ bool withOx = true, }) {
    if (this == null)
      return null;

    return withOx ? "0x${HEX.encode(this)}" : HEX.encode(this);
  }

  /// 0x10 => [1, 0, 0, 0, 0]
  List<int> get bits {
    var char1 = '1'.codeUnitAt(0);
    return bitString(withOb: false).codeUnits.map((b) => b == char1 ? 1 : 0).toList();
  }

  List<int> getBits(int bitOffset, [int bitLen]) {
    int start = bitOffset ~/ 8;
    int end = bitLen != null ? (bitOffset + bitLen + 7) ~/ 8 : length;

    return subView(start, end).bits.sublist(bitOffset % 8, bitLen != null ? bitOffset % 8 + bitLen : null);
  }

  Uint8List toVarBytes() {
    var bitOffset = 0;

    var bs = <int> [];
    var offsetEnd = length * 8;

    var byteOffs = 0;
    while (bitOffset < offsetEnd) {
      byteOffs = bitOffset ~/ 8;
      var b = (this[byteOffs] << (7 - bitOffset % 8)) & 0x7F;

      if (bitOffset % 8 > 2 && byteOffs < length) {
        b |= this[byteOffs + 1];
      }

      bs.add((byteOffs == length ? 0 : 0x80) | b);
      bitOffset += 7;
    }

    throw UnimplementedError('not tested...');

    return bs.bytes;
  }

  String bitString({ bool withOb = true, }) {
    var str = map((f) => f.bitString(withOb: false, width: 8)).join('');

    return withOb ? "0b$str" : str;
  }

  /// [1, 0, 0, 0, 0] => [0x10];
  static Uint8List fromBits(List<int> bits) {
    var bitLen = bits.length;
    var byteLen = (bitLen + 7) ~/ 8;
    var bs = Uint8List(byteLen);
    var byte = 0;

    var rev = bits.reversed;

    for (var idx = 0; idx < bitLen; ++idx) {
      byte |= (rev.elementAt(idx) & 0x1) << (idx % 8);
      // print("byte: ${byte.bitString()}, ele: ${rev.elementAt(idx)}, idx: $idx.");

      if ((idx % 8) == 7) {
        bs[idx  ~/ 8] = byte;
        byte = 0;
      }
    }

    if (byte != 0)
      bs[byteLen - 1] = byte;

    return bs;
  }

  static Uint8List fromHexString(String hex) {
    return Uint8List.fromList(HEX.decode(hex));
  }

  static Uint8List fromUtf8String(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  static Uint8List concatAll(List<List<int>> lists) {
    return lists.reduce((sum, list) => sum + list);
  }

  Uint8List concat(List<List<int>> lists) {
    lists.insert(0, this);
    return Uint8List.fromList(lists.reduce((sum, list) => sum + list));
  }

  ByteDataReader get reader {
    ByteDataReader r = ByteDataReader();
    r.add(this);
    return r;
  }

  int get byteHashCode {
    var bytes = this;

    var length = bytes.length;
    int value = 0;
    for(int i = 0; i < length; i++) {
      value ^= bytes[i] << (((length - i - 1) % 8) * 8);
    }
    return value;
  }
}

Uint8List concat(List<List<int>> lists) {
  return Uint8List.fromList(lists.reduce((sum, list) => sum + list));
}


extension StringExt on String {
  String between(String start, String end) {
    var genStart = indexOf(start);
    var genEnd = indexOf(end);

    return substring(genStart, genEnd);
  }
}

extension IntListExt on List<int> {

  void fill(int val) {
    fillRange(0, length, val ?? 0);
  }

  void fillStep(int val, int step) {
    for (int i = 0; i < length; ++i) {
      this[i] = val;
      val += step;
    }
  }

  void fillZero() { fill(0); }

  Uint8List get bytes => Uint8List.fromList(this);
}

extension Uint8Ext on Uint8List {
  static const size = 1;

  Uint8List subView([int start, int end]) {
    var len = end != null ? (end - start) : null;
    start = offsetInBytes + (start ?? 0)*size;

    return Uint8List.view(buffer, start, len);
  }
}

extension Uint32Ext on Uint32List {
  static const size = 4;

  Uint32List subView([int start, int end]) {
    var len = end != null ? (end - start) : null;
    start = offsetInBytes + (start ?? 0)*size;

    return Uint32List.view(buffer, start, len);
  }
}


extension ByteDataWriterExt on ByteDataWriter {

  writeVarLen(int len) {
    if (len < 0)
      throw new IllegalArgumentException("TLV-length should not less than 0.");

    if (len < 0x7F) writeUint8(len);
    else if (len < 0x3FFF) {
      writeUint8((len >> 7) | 0x80);
      writeUint8(len & 0x7F);
    } else if (len < 0x1FFFFF) {
      writeUint8((len >> 14) | 0x80);
      writeUint8((len >> 7) | 0x80);
      writeInt8(len & 0x7F);
    } else {
      throw new IllegalArgumentException("TLV-length should not bigger than: ${0x1FFFFFF.hexString()}");
    }
  }

}

extension ByteDataReaderExt on ByteDataReader {

  Uint8List remainBytes() => read(remainingLength);

  int readVarLen() {
    var v = 0;
    bool es = true;

    int length = 0;
    while (es) {
      v = readUint8();
      es = (v & 0x80) == 0x80;
      length = (length << 7) | (v & 0x7F);
    }

    return length;
  }

}


extension ListExt<E> on List<E> {
  List<E> unique<K>([K Function(E) key]) {
    Set uq = {};

    var list = <E>[];
    for (var e in this) {
      var k = key != null ? key(e) : e;
      if (uq.contains(k))
        continue;

      list.add(e);
    }

    return list;
  }
}



int utc() => DateTime.now().millisecondsSinceEpoch;


void copyTo(Uint8List src, Uint8List dest, destOffset) {
  for (int idx = 0; idx < src.length; ++idx)
    dest[destOffset + idx] = src[idx];
}

var rand = Random();
Uint8List randomBytes(int len) {
  Uint8List bytes = Uint8List(len);

  for (len--; len >= 0; --len) {
    bytes[len] = rand.nextInt(0xFF);
  }

  return bytes;
}

extension TimerExt on Timer {

  /// repeat for at most times, or run returns false;
  static void repeat(int times, int interval, dynamic Function() run) {
    Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (--times <= 0) {
        timer.cancel();
        return;
      }

      var shouldContinue = run();

      if (shouldContinue is Future) {
        shouldContinue.then((sc) {
          if (sc == false)
            timer.cancel();
        });

      } else if (shouldContinue == false) {
        timer.cancel();
      }
    });
  }

}

/// repeat for at most times, or @param(run) returns false;
void repeat(int times, int interval, dynamic Function() run) {
  return TimerExt.repeat(times, interval, run);
}

final uuid = Uuid();


void loopRun(int times, dynamic Function() run, { int interval = -1, }) async {
  while (times-- > 0) {
    var shouldContinue = run();

    if (shouldContinue is Future) {
      shouldContinue = await shouldContinue;
    }

    if (shouldContinue == false)
      break;

    if (interval > 0)
      await Future.delayed(Duration(milliseconds: interval));
  }
}

Future<void> delay(int milliseconds) {
  return Future.delayed(Duration(milliseconds: milliseconds));
}

Future<void> postDelay(int milliseconds, Runnable run) {
  return Future.delayed(Duration(milliseconds: milliseconds), run);
}