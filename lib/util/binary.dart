
import 'package:utils/util/storage/index.dart';

class BitInt {
  /// NOTE: Javascript only support bit operation for 32-bit.
  static const int
      MAX_SIZE = 32,
      MAX_VALUE = 0xFFFFFFFF,
      R_SHIFT_VALUE = 0x7FFFFFFF
  ;

  int value = 0;

  BitInt([this.value = 0]);


  int getInt(int offs, int len) {
    if ((offs + len) > MAX_SIZE)
      throw IllegalArgumentException('int operator support max ${MAX_SIZE}bits.');

    if (len == MAX_SIZE && offs == 0)
      return value;

    return (this.value << (MAX_SIZE - len - offs) >> (MAX_SIZE - len)) & (R_SHIFT_VALUE >> (MAX_SIZE - 1 - len));
  }

  void setInt(int val, int offs, int len) {
    if ((offs + len) > MAX_SIZE)
      throw IllegalArgumentException('int operator support max ${MAX_SIZE}bits.');

    if (len == MAX_SIZE && offs == 0) {
      value = val;
      return;
    }

    this.value &= ~(R_SHIFT_VALUE >> (MAX_SIZE - 1 - len) << offs);
    this.value |= (val & (R_SHIFT_VALUE >> (MAX_SIZE - 1 - len))) << offs;
  }


  bool getBit(int offs) {
    if (offs > MAX_SIZE)
      throw IllegalArgumentException('int operator support max ${MAX_SIZE}bits.');

    return (value & (0x1 << offs)) != 0;
  }

  void setBit(bool bit, int offs) {
    if (offs > MAX_SIZE)
      throw IllegalArgumentException('int operator support max ${MAX_SIZE}bits.');

    if (bit) {
      value |= (0x1 << offs);
    } else {
      value &= ~(0x1 << offs);
    }
  }

  @override
  String toString() {
    return "$runtimeType { val: ${value.hex}, bits: ${value.bitString()}, }";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BitInt &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

extension BitIntExt on int {
  bool getBit(int offs) => BitInt(this).getBit(offs);
  int getInt(int offs, int len) => BitInt(this).getInt(offs, len);
}