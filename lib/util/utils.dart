/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:fixnum/fixnum.dart';
import 'package:decimal/decimal.dart';
import 'package:hex/hex.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:utils/util/pair.dart';
import 'package:utils/util/simple_interface.dart';
import 'package:uuid/uuid.dart';
import 'package:fast_gbk/fast_gbk.dart';

import 'error.dart';
import 'none_copy_list.dart';

export 'package:meta/meta.dart';

export 'bus.dart';
export 'error.dart';

const _TAG = "Utils";

/// only used for IDE auto import helper.
@Deprecated('only used for IDE auto import helper.')
class Utils { }

/// JS cannot exceed 53bit for bit-op, we use 48 bits.
const MAX_SAFE_INT_SIZE = 6;
const MAX_SAFE_INT_VALUE = 0xFFFFFFFFFFFF;

extension DateTimeExt on DateTime {
  int get utc => millisecondsSinceEpoch;


  static var AM = "AM";
  static var PM = "PM";

  String get amPm => isAm ? AM : PM;

  bool get isAm => hour24ToAm(hour);

  int get hour12 {
    var h = hour;
    if (h == 0) h = 12;
    else if (h > 12) h -= 12;

    return h;
  }

  static bool hour24ToAm(int hour24) => hour24 < 12;

  static int hour12ToHour24(bool am, int hour12) {
    if (hour12 == 12) {
      return am ? 0 : 12;
    }

    return am ? hour12 : (hour12 + 12);
  }

  int startUtcOfDay([bool utc = false]) {
    var n = utc ? DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true) : this;
    return DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
  }

  String get hour12String {
    return "${hour12.toStringAligned(2)}:${minute.toStringAligned(2)} $amPm";
  }

}

extension NumExtUtils on num {

  /// NOTE: check if in scope [low, high], all included.
  bool isInScope(double low, [double? high]) => this >= low && (high == null || this <= high);

}

extension Int64ExtUtils on Int64 {

  Uint8List toBytesSize(int size) {
    var bytes = toBytes();
    return bytes.sublist(0, size).reversed.toList().bytes;
  }

  String get hex => '0x' + toHexString();

  BigInt toBigInt() => BigInt.parse(toHexString(), radix: 16);

  bool getBit(int offs) => (this & (Int64(0x1) << offs)) != 0;

  double toAmountDouble() {
    return Decimal.fromBigInt(toBigInt())
      .shift(-4)
      .toDouble()
    ;
  }

  String toAmountString({ int decimal = 4, String? leading = "￥", }) {
    var d = Decimal.fromBigInt(toBigInt())
        .shift(-decimal);

    var amt = d.toStringAsFixed(2);
    return leading == null
        ? amt
        : "$leading$amt"
    ;
  }

}

extension DoubleExtUtils on double {

  /// NOTE: check if in scope [low, high], all included.
  bool isInScope(double low, [double? high]) => this >= low && (high == null || this <= high);

  double toScope(double low, [double? high]) => max(low, high != null ? min(high, this) : this);

  String autoRoundString({ int maxDecimal = 1, }) {
    if (round() == this)
      return '${round()}';

    if (maxDecimal == 0) return toStringAsFixed(0);

    if (maxDecimal > 0) {
      var str = toStringAsFixed(maxDecimal);
      var lastNoneZero = str.length - 1;
      for (; lastNoneZero >= 0; --lastNoneZero) {
        var c = str[lastNoneZero];
        if (c != '0') {
          if (c == '.')
            --lastNoneZero;

          break;
        }
      }

      return str.substring(0, lastNoneZero + 1);
    }

    return '$this';
  }

  String get percentString => '$percentNumString%';

  String get percentNumString => '${this < 0.1 ? (this * 100).toStringAsFixed(this == 0 ? 0 : 1) : (this * 100).round()}';
  double get percentNumValue => this * 100;

  Int64 get toAmount => Int64((this * 10000).round());

}

extension EccBigIntExt on BigInt {
  Int64 get int64 => Int64.parseHex(toSigned(64).toRadixString(16));
  int get uint32 => toUnsigned(32).toInt().uint32;
  int get int32 => toSigned(32).toInt();
}

extension IntUtils on int {

  int get uint32 => toUnsigned(32);
  int get int32 => toSigned(32);

  Int64 get int64 => Int64(this);

  DateTime toDateTime({ bool isUtc = false, }) => DateTime.fromMillisecondsSinceEpoch(this, isUtc: isUtc);

  /// NOTE: check if in scope [low, high], all included.
  bool isInScope(int low, [int? high]) => this >= low && (high == null || this <= high);

  /// NOTE: check if in scope [0, size), 'size' excluded.
  bool isInSize(int size) => isInScope(0, size - 1);

  int toScope([int? low, int? high]) => max(low ?? this, min(high ?? this, this));

  Uint8List toBytes(int size) {
    if (size > MAX_SAFE_INT_SIZE && (this ~/ (MAX_SAFE_INT_SIZE + 1)) != 0)
      throw UnsupportedError('int number cannot exceed $MAX_SAFE_INT_SIZE bytes in web/js: $size, please use Int64 type.');

    ByteDataWriter bdw = ByteDataWriter();
    const INT32_SIZE = 4;

    if (size == 1 || size == 2 || size == 4 || size == 8) {
      if (size > INT32_SIZE) {
        bdw.writeInt(size - INT32_SIZE, (this ~/ 0x100000000).int32);
        size = INT32_SIZE;
      }

      bdw.writeInt(size, this.int32);
      return bdw.toBytes();
    } else if (size <= 8) {
      bdw.writeInt(INT32_SIZE, (this ~/ 0x100000000).int32);
      bdw.writeInt(INT32_SIZE, this.int32);
      return bdw.toBytes().sublist(8 - size);
    } else
      throw UnsupportedError('int number cannot exceed 8 bytes: $size.');
  }

  /// width is half-byte width, not full-byte width.
  String hexString({ bool withOx = true, int width = -1, }) {
    return radixString(leading: withOx, width: width, radix: 16);
  }

  String get hex => hexString();

  /// width is bit width, not byte width, 0x10 => 0b10000
  String bitString({ bool withOb = true, int width = -1, }) {
    return radixString(leading: withOb, width: width, radix: 2);
  }

  String toStringAligned(int width, { int radix = 10, }) {
    return radixString(leading: false, width: width, radix: radix);
  }

  /// width is the code unit width, not byte width
  String radixString({ bool leading = true, int width = -1, int radix = 16, }) {
    var str = abs().toRadixString(radix);

    if (width > str.length)
      str = str.padLeft(width, '0');

    var sign = this >= 0 ? "" : "-";

    if (leading) {
      var lStr;
      switch (radix) {
        case 2: lStr = '0b'; break;
        case 16: lStr = '0x'; break;
        default: lStr = '[Radix $radix]'; break;
      }
      return "$sign$lStr$str";
    } else
      return sign + str;
  }

  /// eg:
  /// 0b10011 => [1, 1, 0, 0, 1].
  /// 0b10000 => [0, 0, 0, 0, 1], not [1].
  Uint8List bitsByOffset([int? bitSize]) {
    return this.bitmap(bitSize).reversed.toList().bytes;
  }

  /// size = bit size, not byte size.
  /// returned bits are reserved(for bit stream) like:
  ///   0b10011 => [1, 0, 0, 1, 1]
  ///   0b10000 => [1, 0, 0, 0, 0]
  Uint8List bitmap([int? bitSize]) {
    const MAX_SAFE_BITS = 32;

    int bit;
    if (bitSize != null) {
      assert(bitSize >= 0 && bitSize <= MAX_SAFE_BITS);
    } else {
      bitSize = bitLength;
    }

    Uint8List bits = Uint8List(bitSize);

    for (int idx = 0; idx < bitSize; ++idx) {
      bit = (this >> idx) & 0x1;
      bits[bitSize - idx - 1] = bit;
    }

    return bits;
  }


  bool toBool([bool strict = true]) {
    if (strict && this != 0 && this != 1)
      throw IllegalArgumentException("toBool cannot process a int value not inside: [0, 1].");

    return this == 1;
  }

}

extension ByteUtils on Uint8List {

  Uint8List alignToSize(int size) {
    var delta = length - size;

    if (delta < 0) return this.concat([Uint8List(-delta)]);
    else if (delta == 0) return this;
    else return this.subView(0 ,size);
  }

  Iterable<Uint8List> split(int sliceSize) sync* {
    int offs = 0;

    while (offs < length) {
      int len = min(sliceSize, length - offs);

      yield sublist(offs, offs + len);
      offs += len;
    }
  }

  int toSignedInt(){
    var offset = length * 8;
    var val = toInt();

    if (offset <= 0)
      return val;

    if (this[0] & 0x80 != 0) {
      val &= ~(0x1 << (offset - 1));
      var s = -1 << offset;
      return val | s;
    } else {
      return val | (0x1 << (offset - 1));
    }
  }

  Int64 toInt64(){
    var bytes = this;

    var length = bytes.length;
    if (length == 0 || length > 8) {
      throw IllegalArgumentException("bytes length must be > 0 & < 8, not: $length.");
    }

    Int64 value = Int64(0);
    for (int i = 0; i < length; i++) {
      value |= bytes[i] << ((length - i - 1) * 8);
    }
    return value;
  }

  int toInt(){
    var length = this.length;
    if (length == 0 || length > MAX_SAFE_INT_SIZE) {
      throw IllegalArgumentException("bytes length must be > 0 & < $MAX_SAFE_INT_SIZE, not: $length.");
    }

    return toInt64().toInt();
  }

  void copyTo(Uint8List dest, int destOffset, [int? len]) {
    len = len ?? length;

    for (int idx = 0; idx < len; ++idx)
      dest[destOffset + idx] = this[idx];
  }

  /// returns this, no copy.
  Uint8List xor(Uint8List xorIn, [ int thisOffset = 0, int? length ]) {
    length ??= min(xorIn.length, this.length - thisOffset);
    
    for (int idx = 0; idx < length; ++idx)
      this[thisOffset + idx] ^= xorIn[idx];

    return this;
  }

  Uint8List copy([int? start, int? end]) {
    return sublist(start ?? 0, end);
  }

  /// returns this, no copy.
  Uint8List or(Uint8List orIn, [ int thisOffset = 0, int? length ]) {
    length = length ?? orIn.length;

    for (int idx = 0; idx < length; ++idx)
      this[thisOffset + idx] |= orIn[idx];

    return this;
  }

  bool equals(List<int>? other) {
    if (other == null || other.length != length)
      return false;

    for (var idx = 0; idx < length; ++idx) {
      if (other[idx] != this[idx])
        return false;
    }

    return true;
  }

  String hexString({ bool withOx = true, }) {
    return withOx ? "0x${HEX.encode(this)}" : HEX.encode(this);
  }

  String get hex => hexString();

  String base64String() {
    return base64Encode(this);
  }

  String get base64 => base64String();

  /// 0x10 => [0, 0, 0, 1, 0, 0, 0, 0]
  List<int> get bitmap {
    var char1 = '1'.codeUnitAt(0);
    return bitString(withOb: false).codeUnits.map((b) => b == char1 ? 1 : 0).toList();
  }

  List<int> getBitmap(int bitOffset, [int? bitLen]) {
    int start = bitOffset ~/ 8;
    int end = bitLen != null ? (bitOffset + bitLen + 7) ~/ 8 : length;

    return subView(start, end).bitmap.sublist(bitOffset % 8, bitLen != null ? bitOffset % 8 + bitLen : null);
  }

  Uint8List toVarBytes() {
    if (length > 4) throw IllegalArgumentException('toVarBytes only support bytes.length in [0, 4], not: $length.');

    var i64 = toInt64();
    var bitSize = i64.bitLength;

    // +2 with byte-length-bits.
    var size = max(1, (bitSize + 2 + 7) ~/ 8);
    if (size > 4) throw IllegalArgumentException('toVarBytes only support bits.length in [0, 30], not: $bitSize.');

    // latest part.
    var bytes = i64.toBytesSize(size);
    // print('${this.hex} => ${i64.hex} / ${bytes.hex}.');
    bytes[0] |= ((size - 1) << 6);

    return bytes;
  }

  String bitString({ bool withOb = true, int width = -1, bool cutTail = false, }) {
    var str = map((f) => f.bitString(withOb: false, width: 8)).join('');

    if (width > str.length)
      str = str.padLeft(width, '0');

    if (cutTail && width > 0 && width < str.length)
      str = str.substring(0, width);

    return withOb ? "0b$str" : str;
  }

  /// [0,1,0,1, 0,0,0,1, 0,0,0,0] => [0x05, x10];
  static Uint8List fromBitmap(List<int> bits) {
    var bitLen = bits.length;
    var byteLen = (bitLen + 7) ~/ 8;
    var bs = Uint8List(byteLen);
    var byte = 0;

    for (var idx = 0; idx < bitLen; ++idx) {
      byte |= (bits[bitLen - idx - 1] & 0x1) << (idx % 8);

      if ((idx % 8) == 7) {
        // print("byte: ${byte.bitString()}, idx: $idx.");
        bs[byteLen - (idx  ~/ 8) - 1] = byte;
        byte = 0;
      }
    }

    if (byte != 0)
      bs[0] = byte;

    // print("bytes: ${bs.hex}, bits: ${bits.join('')}.");
    return bs;
  }

  static Uint8List fromHexString(String hex) {
    return Uint8List.fromList(HEX.decode(hex));
  }

  static Uint8List fromUtf8String(String str) {
    return Uint8List.fromList(utf8.encode(str));
  }

  static Uint8List fromGbkString(String str) {
    return Uint8List.fromList(gbk.encode(str));
  }

  static Uint8List concatAll(List<List<int>> lists) {
    return Uint8List(0).concat(lists);
  }

  String get utf8String => utf8.decode(this);

  Uint8List concat(List<List<int>> lists) {
    var r = <int> [...this];
    for (var list in lists) {
      r.addAll(list);
    }

    return Uint8List.fromList(r);
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
      value ^= bytes[i] << (((length - i - 1) % 4) * 8);
    }
    return value;
  }
}

Uint8List concat(List<List<int>> lists) {
  return Uint8List.fromList(lists.reduce((sum, list) => sum + list));
}


extension StringExt on String {

  static Map<String, String> _localStringMap = {};

  String? get nullIfEmpty => isEmpty ? null : this;

  Uint8List get hexDecodedBytes => ByteUtils.fromHexString(this);
  Uint8List get base64DecodedBytes => base64Decode(this);

  List<String> splitSized(int width) {
    List<String> ss = [];

    var idx = 0;
    var len = length;
    while (idx < len) {
      var w = min(len - idx, width);
      ss.add(substring(idx, idx + w));
      idx += w;
    }

    return ss;
  }

  String alignTo(int width, [ String token = " " ]) {
    var l = this.length;
    if (l >= width)
      return this;

    return "${List<String>.filled(width - l, token).join("")}$this";
  }

  String removeBetween(String start, String end) {
    var rmStart = indexOf(start);
    var rmEnd = indexOf(end);

    var head = substring(0, rmStart);
    var tail = substring(rmEnd + end.length);

    return head + tail;
  }

  String between(String start, String end) {
    var genStart = indexOf(start);
    var genEnd = indexOf(end);

    return substring(genStart, genEnd);
  }


  int localCompare(String r, [checkSeq = true]) {
    if (r == null && this == null)
      return 0;

    if (r == null)
      return 1;

    return this.compareString(checkSeq: checkSeq).compareTo(r.compareString(checkSeq: checkSeq));
  }

  String compareString({ checkSeq = true, }) {
    var cached = _localStringMap[this];
    if (cached != null)
      return cached;

    var units = <int> [];

    var full = trim().toLowerCase();

    String name = full;
    int? seq;
    var firstNoneNum = -1;

    const MAX_NUM = 5;
    if (checkSeq) {
      /// MAX_NUM: [1, 4, 7, 11].
      try {
        var lastNoneNum = full.length - 1;
        for (; lastNoneNum >= 0; --lastNoneNum) {
          var code = full.codeUnitAt(lastNoneNum);
          if (code < 0x30 || code > 0x39)
            break;
        }

        var count = full.length - lastNoneNum - 1;
        if (count > 0 && count <= MAX_NUM) {
          var numTail = full.substring(lastNoneNum + 1);
          seq = int.parse(numTail);
          name = full.substring(0, lastNoneNum + 1);
        }
      } catch (e) {
        // Log.w(_TAG, () => '');
        seq = null;
        name = full;
      }

      for (var idx = 0; idx < full.length; ++idx) {
        if (idx >= MAX_NUM)
          break;

        var code = full.codeUnitAt(idx);

        if (code < 0x30 || code > 0x39) { // not num
          firstNoneNum = idx;
          break;
        }
      }
    }

    if (firstNoneNum > 0) {
      var headSeq = int.parse(name.substring(0, firstNoneNum));
      units.add(0x0);

      if (MAX_NUM >= 5)
        units.add((headSeq >> 16) & 0xFFFF);
      units.add(headSeq & 0xFFFF);

      name = full.substring(firstNoneNum);
    }

    for (var unit in name.codeUnits) {
      if (unit < 0xFF) {
        units.add(unit);
        continue;
      }

      try {
        var py = PinyinHelper.getFirstWordPinyin(String.fromCharCode(unit));
        units.addAll(py.codeUnits);
      } catch (e) {
        units.add(unit);
      }
    }

    if (seq != null) {
      units.add(0x0);

      if (MAX_NUM >= 5)
        units.add((seq >> 16) & 0xFFFF);
      units.add(seq & 0xFFFF);
    }

    var str = String.fromCharCodes(units);

    // print('compareString: seq: $seq, $this => $str.');
    return _localStringMap[this] = str;
  }

  String get shortPinyin {
    try {
      return PinyinHelper.getShortPinyin(this);
    } catch(e) {
      print("[ERROR] trans to pinyin failed: $this, error: ${errorMsg(e)}");
      // Log.w(_TAG, () => "trans to pinyin failed: $this, error: ${errorMsg(e)}");
      return this;
    }
  }

  Uint8List get gbkBytes => gbk.encode(this).bytes;

  Uint8List get utf8Bytes => utf8.encode(this).bytes;
  Uint8List get codeBytes => codeUnits.bytes;

}

extension ListNullableExt<E> on List<E?> {

  void addIfNotNull(E? elem) {
    if (elem != null) add(elem);
  }

  List<E> toNoneNulls() {
    List<E> r = [];
    for (var item in this) {
      if (item != null)
        r.add(item);
    }

    return r;
  }

}

extension IterableNullableExt<E> on Iterable<E?> {

  Iterable<E> toNoneNulls() sync* {
    for (var item in this) {
      if (item != null)
        yield item;
    }
  }
}

extension StringNullableListExt on List<String?> {

  void removeEmptyNulls() {
    removeWhere((e) => e == null || e == '');
  }

  String joinExcludeEmptyNulls([String separator = ""]) {
    removeEmptyNulls();
    return join(separator);
  }

}

extension IntListExt on List<int> {

  void fill(int val) {
    fillRange(0, length, val);
  }

  void fillStep(int val, int step) {
    for (int i = 0; i < length; ++i) {
      this[i] = val;
      val += step;
    }
  }

  void fillZero() { fill(0); }

  Uint8List get bytes => this is Uint8List ? this as Uint8List : Uint8List.fromList(this);

  int toIntAsBitIndex({ int? endIndex }) {
    int r = 0;

    for (var bitIndex in this) {
      if (bitIndex < 0)
        throw IllegalArgumentException('bitIndex($bitIndex) CANNOT < 0, all bitIndex: $this.');

      if (endIndex != null && bitIndex > endIndex)
        throw IllegalArgumentException('bitIndex($bitIndex) out of range $endIndex, all bitIndex: $this.');

      r |= (0x1 << bitIndex);
    }

    return r;
  }

  /// format: [start, end, [step]].
  Iterable<int> it({ bool reversed = false, }) sync * {
    if (length < 2 || length > 3)
      throw UnsupportedError('Only support');

    var start = this[0], end = this[1];
    var step = length == 3 ? this[2] : 1;

    if (!reversed) {
      for (; start < end; start += step)
        yield start;
    } else {
      end -= step;
      for (; end >= start; end -= step)
        yield end;
    }

  }

}

Iterable<int> numIt(int start, int end, { int? step = 1, bool reversed = false, }) =>
    [start, end, step ?? 1].it(reversed: reversed);

extension Uint8Ext on Uint8List {
  static const size = 1;

  Uint8List subView([int? start, int? end]) {
    start ??= 0;
    var len = end != null ? (end - start) : null;

    return Uint8List.view(buffer, offsetInBytes + start*size, len);
  }
}

extension Uint32Ext on Uint32List {
  static const size = 4;

  Uint32List subView([int? start, int? end]) {
    start ??= 0;
    var len = end != null ? (end - start) : null;

    return Uint32List.view(buffer, offsetInBytes + start*size, len);
  }

  Uint8List get bytesView => Uint8List.view(buffer, offsetInBytes, lengthInBytes);

  // Uint32List operator +(int offset) => subView(offset);

}


extension ByteDataWriterExt on ByteDataWriter {

  void writeUint40(int value, [Endian? endian]) {
    List<int> bytes = value.toBytes(5);

    if (endian == Endian.little) {
      bytes = bytes.reversed.toList();
    }

    write(bytes);
  }

  void writeLByte(Uint8List? bytes) {
    this.writeUint8(bytes?.length ?? 0);
    if (bytes != null) this.write(bytes);
  }

  void writeVarLen(int len) {
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

  int readUint48([Endian? endian]) {
    var bytes = read(6);

    if (endian == Endian.little) {
      bytes = bytes.reversed.toList().bytes;
    }

    return bytes.toInt();
  }

  int readUint40([Endian? endian]) {
    var bytes = read(5);

    if (endian == Endian.little) {
      bytes = bytes.reversed.toList().bytes;
    }

    return bytes.toInt();
  }

  Uint8List readLByte() {
    var len = this.readUint8();
    return this.read(len);
  }

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


extension MapExt<K, V> on Map<K, V> {

  bool deepEquals(Map<K, V>? o) {
    if (o == null) return false;

    if (length != o.length)
      return false;

    for (var key in keys) {
      if (this[key] != o[key])
        return false;
    }

    return true;
  }

}

extension JsonMapExt on Map<String, dynamic> {

  int? intValue(String key, { int? fallback, }) {
    var d = this[key];
    return d == null ? fallback : (d as num).toInt();
  }

  double? doubleValue(String key, { double? fallback, }) {
    var d = this[key];
    return d == null ? fallback : (d as num).toDouble();
  }

  bool? boolValue(String key, { bool? fallback, }) => this[key] ?? fallback;

  String? stringValue(String key, { String? fallback, }) => this[key] ?? fallback;

  Uint8List? base64Value(String key, { Uint8List? fallback, }) {
    var d = this[key];
    return d == null ? fallback : base64Decode(d);
  }

  Uint8List? hexValue(String key, { Uint8List? fallback, }) {
    var d = this[key];
    return d == null ? fallback : ByteUtils.fromHexString(d);
  }

}

extension IterableExt<E> on Iterable<E> {

  Iterable<int> offsetsWhere(bool test(int index, E elem)) sync* {
    int offs = 0;

    for (var elem in this) {
      if (test(offs, elem)) yield offs;
      offs++;
    }
  }

  Iterable<Iterable<E>> splitSized(int width) sync* {
    var it = iterator;

    while (it.moveNext()) {
      var idx = 0;
      yield () sync *{
        yield it.current;

        while (++idx < width && it.moveNext()) {
          yield it.current;
        }
      } ();

      // skip not used items.
      while (++idx < width && it.moveNext()) { }
    }
  }


  Pair<List<E>, List<E>> splitList(bool test(E elem)) {
    List<E> trueList = [];
    List<E> falseList = [];

    for (var elem in this) {
      test(elem)
          ? trueList.add(elem)
          : falseList.add(elem)
      ;
    }

    return Pair(trueList, falseList);
  }

  Map<KEY, VALUE> toMap<KEY, VALUE>(MapEntry<KEY, VALUE> toEntry(E elem)) {
    return <KEY, VALUE>{ }..addEntries(map(toEntry).where((element) => e != null));
  }

  E? firstWhereNullable(bool test(E elem), { E? orElse()?, }) {
    for (E element in this) {
      if (test(element)) return element;
    }

    if (orElse != null)
      return orElse();

    return null;
  }


  Set<K> uniqueField<K>([K Function(E)? key]) {
    Set<K> uq = {};

    for (var e in this) {
      var k = key != null ? key(e) : (e as K);
      uq.add(k);
    }

    return uq;
  }

  List<T> mapList<T>(T toElement(E e)) => map(toElement).toList();

  Map<T, int> count<T>([T Function(E e)? toCountKey]) {
    Map<T, int> counts = {};

    for (var e in this) {
      T k = toCountKey == null ? e as T : toCountKey(e);
      var c = counts[k];
      counts[k] = (c ?? 0) + 1;
    }

    return counts;
  }

  E? min([int Function(E l, E r)? compare]) {
    final c = compare;
    return max(c != null ? (l, r) => c(r, l) : (l, r) => ((r as dynamic) - l));
  }

  E? max([int Function(E l, E r)? compare]) {
    E? m;

    for (var e in this) {
      if (m == null) {
        m = e;
        continue;
      }

      if (compare != null ? compare(e, m) > 0 : ((e as dynamic) - m) > 0) {
        m = e;
      }
    }

    return m;
  }

  Map<T, List<E>> groupBy<T>(T groupByKey(E elem), { bool excludeNullItem = true, bool excludeNullKey = true, }) {
    Map<T, List<E>> m = {};

    for (var e in this) {
      if (excludeNullItem && e == null)
        continue;

      var k = groupByKey(e);
      if (excludeNullKey && k == null)
        continue;

      var l = m[k] ?? (m[k] = []);
      l.add(e);
    }

    return m;
  }

  Stream<E> whereAsync(Future<bool> Function(E elem) where) async * {
    for (var elem in this) {
      if (await where(elem))
        yield elem;
    }
  }

  Iterable<E> excluded(Iterable<E> excludes) {
    var result = [ ...this, ];
    return result..removeWhere((element) => excludes.contains(element));
  }

  List<E> joinItemList(E j, { bool Function(E previous)? test, }) {
    return joinItem(j, test: test).toList();
  }

  Iterable<E> joinItem(E j, { bool Function(E previous)? test, }) sync* {
    bool first = true;

    E? previous;
    for (var i in this) {
      if (first) first = false;
      else if (test == null || test(previous!)) yield j;

      yield i;
      previous = i;
    }
  }

  Iterable<E> joinList(Iterable<E> l) sync* {
    bool first = true;

    for (var i in this) {
      if (first) first = false;
      else yield* l;

      yield i;
    }
  }


  E? get firstNullable => this.isEmpty ? null : first;
  E? get lastNullable => this.isEmpty ? null : last;
}

extension ListExt<E> on List<E> {

  List<E> subView([int? start, int? end]) {
    return NoneCopyList(this, start, end);
  }

  List<E> clone() => [...this];

  // order is same to o.
  List<E> union(List<E> o) {
    Set<E> set = toSet();
    return o.where((elem) => set.contains(elem)).toList();
  }

  bool deepEquals(List<E> o) {
    if (length != o.length)
      return false;

    for (var idx = 0; idx < length; ++idx) {
      if (this[idx] != o[idx])
        return false;
    }

    return true;
  }

  List<E> unique<K>([K Function(E)? key]) {
    Set uq = {};

    var list = <E>[];
    for (var e in this) {
      var k = key != null ? key(e) : e;

      if (k == null) {
        if (e != null)
          list.add(e);

        continue;
      }

      if (uq.contains(k))
        continue;

      uq.add(k);
      list.add(e);
    }

    return list;
  }

  Iterable<int> usablePositions(int max, int pos(E elem), { bool usable(E elem)? }) sync* {
    var items = unique(pos)..sort((l, r) => pos(l) - pos(r));

    int p = 0;
    for (var item in items) {
      var ip = pos(item);

      while (p < ip) {
        yield p++;
      }

      if (usable != null && usable(item)) yield ip;
      // next pos.
      p = ip + 1;
    }

    while (p < max) yield p++;
  }

  int getUsablePosition(int max, int pos(E elem), { bool usable(E elem, int pos)? }) {
    var items = unique(pos)..sort((l, r) => pos(l) - pos(r));

    usable ??= (e, p) => pos(e) != p;

    int p = 0;
    for (var item in items) {
      if (usable(item, p))
        break;

      ++p;
    }

    // print('getUsablePosition: $p, items: $items.');

    return p < max ? p : -1;
  }

  Iterable<T> mapIndexed<T>(T f(E item, int index)) {
    int idx = 0;
    return map((e) => f(e, idx++));
  }

  int? indexWhereFallback(bool f(E item), [ int? fallback ]) {
    int idx = this.indexWhere(f);
    return idx >= 0
        ? idx
        : fallback;
  }

  Future<List<Pair<T, E>>> toPairedReversed<T>(FutureOr<T> getPair(E elem), { bool excludeNull = true, bool? async, }) async {
    List<Pair<T, E>> result = [];

    for (var e in this) {
      var p = getPair(e);

      if (async ??= p is Future)
        p = await p;

      if (excludeNull && p == null)
        continue;

      result.add(Pair<T, E>(p as T, e));
    }

    return result;
  }


  Future<List<Pair<E, T>>> toPaired<T>(FutureOr<T> getPair(E elem), { bool excludeNull = true, bool? async, }) async {
    List<Pair<E, T>> result = [];

    for (var e in this) {
      var p = getPair(e);

      if (async ??= p is Future)
        p = await p;

      if (excludeNull && p == null)
        continue;

      result.add(Pair<E, T>(e, p as T));
    }

    return result;
  }

  void removeDuplicated<T>({ T duplicateKey(E elem)? }) {
    if (duplicateKey == null) {
      var all = toSet().toList();
      if (all.length != length) {
        clear();
        addAll(all);
      }

      return;
    }

    var set = <T> { };
    var results = <E> [];
    for (var e in this) {
      if (set.add(duplicateKey(e))) {
        results.add(e);
      }
    }

    if (results.length != length) {
      clear();
      addAll(results);
    }
  }

  void removeNulls<T>() {
    removeWhere((e) => e == null);
  }

}


int? serverUtcDelta;
int utc() => DateTime.now().millisecondsSinceEpoch + (serverUtcDelta ?? 0);

int _lastUtc = 0;
int uniqueUtc() {
  var u = utc();
  if (u <= _lastUtc) u = ++_lastUtc;
  _lastUtc = u;
  return u;
}

double log10(num x) => log(x) / ln10;

void copyTo(Uint8List src, Uint8List dest, destOffset) {
  for (int idx = 0; idx < src.length; ++idx)
    dest[destOffset + idx] = src[idx];
}

var rand = Random();
var randSecure = Random.secure();
Uint8List randomBytes(int len, { Uint8List? bytes, bool secure = true, bool noDuplicates = false, }) {
  bytes ??= Uint8List(len);

  var r = secure ? randSecure : rand;
  if (noDuplicates) {
    if (len > 128) throw IllegalArgumentException('randomBytes() with noDuplicates = true, len should <= 128, not: $len.');

    Set<int> duplicates = {};
    for (len--; len >= 0; --len) {
      var v = r.nextInt(0xFF);
      while (duplicates.contains(v)) {
        v = r.nextInt(0xFF);
      }

      duplicates.add(v);
      bytes[len] = v;
    }
  } else {
    for (len--; len >= 0; --len) {
      bytes[len] = r.nextInt(0xFF);
    }
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


Future<void> loopRun(int times, dynamic Function() run, { int interval = -1, int delayMs = -1, }) async {
  if (delayMs > 0)
    await delay(delayMs);

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

/// manualStop() return false will stop delay.
Future<void> delay(int milliseconds, { bool continueDelay()?, int checkInterval = 50, }) {
  if (continueDelay == null)
    return Future.delayed(Duration(milliseconds: milliseconds));

  return (() async {
    var start = utc();

    while (continueDelay() != false && start + milliseconds > utc()) {
      var t = min(checkInterval, start + milliseconds - utc());
      if (t <= 0)
        break;

      await Future.delayed(Duration(milliseconds: t));
    }
  }) ();
}

Future<void> postDelay(int milliseconds, Runnable run) {
  return Future.delayed(Duration(milliseconds: milliseconds), run);
}