/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:buffer/buffer.dart';
import 'package:utils/util/storage/index.dart';

/**
 * @see https://github.com/numpy/numpy/blob/master/numpy/core/src/npymath/halffloat.c
 */
class float16 implements Comparable<float16> {
  /*

const NPY_HALF_ZERO = 0x0000;
const NPY_HALF_PZERO = 0x0000;
const NPY_HALF_NZERO = 0x8000;
const NPY_HALF_ONE = 0x3c00;
const NPY_HALF_NEGONE = 0xbc00;
const NPY_HALF_PINF = 0x7c00;
const NPY_HALF_NINF = 0xfc00;
const NPY_HALF_NAN = 0x7e00;

const NPY_MAX_HALF = 0x7bff;
   */
  static const
    zero = const float16.fromHex(0x0000),
    zero_p = const float16.fromHex(0x0000),
    zero_n = const float16.fromHex(0x8000),

    one = const float16.fromHex(0x3c00),
    one_n = const float16.fromHex(0xbc00),
    inf = const float16.fromHex(0x7c00),
    inf_n = const float16.fromHex(0xfc00),
    nan = const float16.fromHex(0x7e00)
  ;


  final int hex;

  float16.fromBytes(Uint8List bytes)
      : assert(bytes.length == 2),
        hex = bytes.toInt();

  const float16.fromHex(this.hex);

  float16.fromDouble(double val) : this.fromHex(npy_double_to_half(val));

  int get unsignedHex => hex;
  int get signedHex => (-1 & 0xFFFF) | unsignedHex;

  double get float => npy_half_to_double(this);
  int get integer => float.toInt();

  Uint8List get bytes => hex.toBytes(2);

  float16m get mono => float16m.fromHex(float16m.toMonoHex(hex));

  @override
  int compareTo(other) => (float - other.float).toInt();

  bool operator >(/*float16*/ dynamic o) => float > (o is float16 ? o.float : o);
  bool operator >=(/*float16*/ dynamic o) => float >= (o is float16 ? o.float : o);
  bool operator <(/*float16*/ dynamic o) => float < (o is float16 ? o.float : o);
  bool operator <=(/*float16*/ dynamic o) => float <= (o is float16 ? o.float : o);

  @override
  bool operator ==(Object o) => identical(this, o)
      || (float == (o is float16 ? o.float : float == o));

  @override
  int get hashCode => hex.hashCode;

  String debugString() {
    return "$float[${hex.hexString()}]";
  }

  @override
  String toString() {
    return "$float";
  }
}

/// binary monotonous float 16
class float16m extends float16 {

  static int toMonoHex(int from) {
    if ((from & 0x8000) != 0) {
      return from ^ 0xFFFF;
    } else
      return from ^ 0x8000;
  }

  static int fromMonoHex(int from) {
    if ((from & 0x8000) != 0) {
      return from ^ 0x8000;
    } else
      return from ^ 0xFFFF;
  }

  float16m.fromBytes(Uint8List bytes) : super.fromHex(fromMonoHex(bytes.toInt()));

  const float16m.fromHex(int hex) : super.fromHex(hex);

  float16m.fromDouble(double val) : this.fromHex(npy_double_to_half(val));

  float16 get normal => float16.fromDouble(float);

  @override
  Uint8List get bytes => toMonoHex(hex).toBytes(2);
}

const NPY_HALF_ZERO = 0x0000;
const NPY_HALF_PZERO = 0x0000;
const NPY_HALF_NZERO = 0x8000;
const NPY_HALF_ONE = 0x3c00;
const NPY_HALF_NEGONE = 0xbc00;
const NPY_HALF_PINF = 0x7c00;
const NPY_HALF_NINF = 0xfc00;
const NPY_HALF_NAN = 0x7e00;

const NPY_MAX_HALF = 0x7bff;

/*
 * This chooses between 'ties to even' and 'ties away from zero'.
 */
const NPY_HALF_ROUND_TIES_TO_EVEN = true;
/*
 * If these are 1, the conversions try to trigger underflow,
 * overflow, and invalid exceptions in the FP system when needed.
 */
const NPY_HALF_GENERATE_OVERFLOW = false;
const NPY_HALF_GENERATE_UNDERFLOW = false;
const NPY_HALF_GENERATE_INVALID = true;

/*
 ********************************************************************
 *                   HALF-PRECISION ROUTINES                        *
 ********************************************************************
 */

double bytes2double(Uint8List bytes) {
  assert(bytes.length == 8);
  var r = ByteDataReader();
  r.add(bytes);
  return r.readFloat64();
}

Uint8List double2bytes(double d) {
  var w = ByteDataWriter();
  w.writeFloat64(d);
  return w.toBytes();
}

double npy_half_to_double(float16 h) {
  var retbits = npy_halfbits_to_doublebits(h.hex);
  var str = retbits.toRadixString(16);
  str = str.length < 16
      ? "000000000000000000000000000000000000".substring(0, 16 - str.length) + str
      : str.substring(0, 16);

  return bytes2double(ByteUtils.fromHexString(str));
}

int npy_double_to_half(double d) {
  return npy_doublebits_to_halfbits(double2bytes(d));
}

bool npy_half_iszero(float16 h) {
  return (h.unsignedHex & 0x7fff) == 0;
}

bool npy_half_isnan(float16 bs) {
  var h = bs.unsignedHex;
  return ((h & 0x7c00) == 0x7c00) && ((h & 0x03ff) != 0x0000);
}

bool npy_half_isinf(float16 bs) {
  var h = bs.unsignedHex;
  return ((h & 0x7fff) == 0x7c00);
}

bool npy_half_isfinite(float16 bs) {
  var h = bs.unsignedHex;
  return ((h & 0x7c00) != 0x7c00);
}

bool npy_half_signbit(float16 bs) {
  var h = bs.unsignedHex;
  return (h & 0x8000) != 0;
}

int npy_half_spacing(float16 bs) {
  var h = bs.unsignedHex;
  int ret;
  int h_exp = h & 0x7c00;
  int h_sig = h & 0x03ff;
  if (h_exp == 0x7c00) {
    if (NPY_HALF_GENERATE_INVALID) {
      throw IllegalArgumentException('npy_set_floatstatus_invalid');
    }

    ret = NPY_HALF_NAN;
  } else if (h == 0x7bff) {
    if (NPY_HALF_GENERATE_OVERFLOW) {
      throw IllegalArgumentException('npy_set_floatstatus_overflow');
    }
    ret = NPY_HALF_PINF;
  } else if ((h & 0x8000) != 0 && h_sig == 0) {
    /* Negative boundary case */
    if (h_exp > 0x2c00) {
      /* If result is normalized */
      ret = h_exp - 0x2c00;
    } else if (h_exp > 0x0400) {
      /* The result is a subnormal, but not the smallest */
      ret = 1 << ((h_exp >> 10) - 2);
    } else {
      ret = 0x0001; /* Smallest subnormal half */
    }
  } else if (h_exp > 0x2800) {
    /* If result is still normalized */
    ret = h_exp - 0x2800;
  } else if (h_exp > 0x0400) {
    /* The result is a subnormal, but not the smallest */
    ret = 1 << ((h_exp >> 10) - 1);
  } else {
    ret = 0x0001;
  }

  return ret;
}

int npy_half_copysign(float16 x, float16 y) {
  return (x.unsignedHex & 0x7fff) | (y.unsignedHex & 0x8000);
}

float16 npy_half_nextafter(float16 x, float16 y) {
  int ret;

  if (npy_half_isnan(x) || npy_half_isnan(y)) {
    ret = NPY_HALF_NAN;
  } else if (npy_half_eq_nonan(x, y)) {
    ret = x.unsignedHex;
  } else if (npy_half_iszero(x)) {
    ret = (y.unsignedHex & 0x8000) + 1; /* Smallest subnormal half */
  } else if (x.unsignedHex & 0x8000 == 0) {
    /* x > 0 */
    if (x.signedHex > y.signedHex) {
      /* x > y */
      ret = x.unsignedHex - 1;
    } else {
      ret = x.unsignedHex + 1;
    }
  } else {
    if ((y.unsignedHex & 0x8000) == 0 || (x.unsignedHex & 0x7fff) > (y.unsignedHex & 0x7fff)) {
      /* x < y */
      ret = x.unsignedHex - 1;
    } else {
      ret = x.unsignedHex + 1;
    }
  }

  float16 r = float16.fromHex(ret);
  if (NPY_HALF_GENERATE_OVERFLOW) {
    if (npy_half_isinf(r) && npy_half_isfinite(x)) {
      throw IllegalArgumentException('npy_set_floatstatus_overflow');
    }
  }

  return r;
}

bool npy_half_eq_nonan(float16 h1, float16 h2) {
  return (h1 == h2 || ((h1.unsignedHex | h2.unsignedHex) & 0x7fff) == 0);
}

bool npy_half_eq(float16 h1, float16 h2) {
/*
     * The equality cases are as follows:
     *   - If either value is NaN, never equal.
     *   - If the values are equal, equal.
     *   - If the values are both signed zeros, equal.
     */
  return (!npy_half_isnan(h1) && !npy_half_isnan(h2)) &&
      (h1 == h2 || ((h1.unsignedHex | h2.unsignedHex) & 0x7fff) == 0);
}

bool npy_half_ne(float16 h1, float16 h2) {
  return !npy_half_eq(h1, h2);
}

bool npy_half_lt_nonan(float16 fh1, float16 fh2) {
  int h1 = fh1.unsignedHex, h2 = fh2.unsignedHex;

  if (h1 & 0x8000 != 0) {
    if (h2 & 0x8000 != 0) {
      return (h1 & 0x7fff) > (h2 & 0x7fff);
    } else {
/* Signed zeros are equal, have to check for it */
      return (h1 != 0x8000) || (h2 != 0x0000);
    }
  } else {
    if (h2 & 0x8000 != 0) {
      return false;
    } else {
      return (h1 & 0x7fff) < (h2 & 0x7fff);
    }
  }
}

bool npy_half_lt(float16 h1, float16 h2) {
  return (!npy_half_isnan(h1) && !npy_half_isnan(h2)) && npy_half_lt_nonan(h1, h2);
}

bool npy_half_gt(float16 h1, float16 h2) {
  return npy_half_lt(h2, h1);
}

bool npy_half_le_nonan(float16 fh1, float16 fh2) {
  int h1 = fh1.unsignedHex, h2 = fh2.unsignedHex;

  if (h1 & 0x8000 != 0) {
    if (h2 & 0x8000 != 0) {
      return (h1 & 0x7fff) >= (h2 & 0x7fff);
    } else {
      return true;
    }
  } else {
    if (h2 & 0x8000 != 0) {
/* Signed zeros are equal, have to check for it */
      return (h1 == 0x0000) && (h2 == 0x8000);
    } else {
      return (h1 & 0x7fff) <= (h2 & 0x7fff);
    }
  }
}

bool npy_half_le(float16 h1, float16 h2) {
  return (!npy_half_isnan(h1) && !npy_half_isnan(h2)) && npy_half_le_nonan(h1, h2);
}

bool npy_half_ge(float16 h1, float16 h2) {
  return npy_half_le(h2, h1);
}

/*
 ********************************************************************
 *                     BIT-LEVEL CONVERSIONS                        *
 ********************************************************************
 */

extension BigIntStringExt on String {
  BigInt get bigInt => BigInt.parse(this, radix: 16);
}

extension BigIntIntExt on int {
  BigInt get bigInt => BigInt.from(this);
}

int npy_doublebits_to_halfbits(Uint8List dbits) {
  var d = BigInt.parse(dbits.hexString(withOx: false), radix: 16);
  BigInt d_exp, d_sig;
  int h_sgn, h_exp, h_sig;

  h_sgn = ((d & '8000000000000000'.bigInt) >> 48).toInt() & 0xFFFF;
  d_exp = (d & '7ff0000000000000'.bigInt);

/* Exponent overflow/NaN converts to signed inf/NaN */
  if (d_exp >= '40f0000000000000'.bigInt) {
    if (d_exp == '7ff0000000000000'.bigInt) {
/* Inf or NaN */
      d_sig = (d & '000fffffffffffff'.bigInt);
      if (d_sig != 0.bigInt) {
/* NaN - propagate the flag in the significand... */
        int ret = (0x7c00.bigInt + (d_sig >> 42)).toInt() & 0xFFFF;
/* ...but make sure it stays a NaN */
        if (ret == 0x7c00) {
          ret++;
        }
        return h_sgn + ret;
      } else {
/* signed inf */
        return h_sgn + 0x7c00;
      }
    } else {
/* overflow to signed inf */
      if (NPY_HALF_GENERATE_OVERFLOW) {
        throw IllegalArgumentException('npy_set_floatstatus_overflow');
      }
      return h_sgn + 0x7c00;
    }
  }

/* Exponent underflow converts to subnormal half or signed zero */
  if (d_exp <= '3f00000000000000'.bigInt) {
/*
         * Signed zeros, subnormal floats, and floats with small
         * exponents all convert to signed zero half-floats.
         */
    if (d_exp < '3e60000000000000'.bigInt) {
      if (NPY_HALF_GENERATE_UNDERFLOW) {
/* If d != 0, it underflowed to 0 */
        if ((d & '7fffffffffffffff'.bigInt) != 0) {
          throw IllegalArgumentException('npy_set_floatstatus_underflow');
        }
      }
      return h_sgn;
    }
/* Make the subnormal significand */
    d_exp >>= 52;
    d_sig = ('0010000000000000'.bigInt + (d & '000fffffffffffff'.bigInt));
    if (NPY_HALF_GENERATE_UNDERFLOW) {
/* If it's not exactly represented, it underflowed */
      if ((d_sig & ((1.bigInt << (1051.bigInt - d_exp).toInt()) - 1.bigInt)) != 0) {
        throw IllegalArgumentException('npy_set_floatstatus_underflow');
      }
    }
/*
         * Unlike floats, doubles have enough room to shift left to align
         * the subnormal significand leading to no loss of the last bits.
         * The smallest possible exponent giving a subnormal is:
         * `d_exp = 0x3e60000000000000 >> 52 = 998`. All larger subnormals are
         * shifted with respect to it. This adds a shift of 10+1 bits the final
         * right shift when comparing it to the one in the normal branch.
         */
    assert(d_exp >= 998.bigInt);
    d_sig <<= (d_exp - 998.bigInt).toInt();
/* Handle rounding by adding 1 to the bit beyond half precision */
    if (NPY_HALF_ROUND_TIES_TO_EVEN) {
/*
         * If the last bit in the half significand is 0 (already even), and
         * the remaining bit pattern is 1000...0, then we do not add one
         * to the bit after the half significand.  In all other cases, we do.
         */
      if ((d_sig & '003fffffffffffff'.bigInt) != '0010000000000000'.bigInt) {
        d_sig += '0010000000000000'.bigInt;
      }
    } else {
      d_sig += '0010000000000000'.bigInt;
    }
    h_sig = (d_sig >> 53).toInt() & 0xFFFF;
/*
         * If the rounding causes a bit to spill into h_exp, it will
         * increment h_exp from zero to one and h_sig will be zero.
         * This is the correct result.
         */
    return h_sgn + h_sig;
  }

/* Regular case with no overflow or underflow */
  h_exp = ((d_exp - '3f00000000000000'.bigInt) >> 42).toInt() & 0xFFFF;
/* Handle rounding by adding 1 to the bit beyond half precision */
  d_sig = (d & '000fffffffffffff'.bigInt);
  if (NPY_HALF_ROUND_TIES_TO_EVEN) {
/*
     * If the last bit in the half significand is 0 (already even), and
     * the remaining bit pattern is 1000...0, then we do not add one
     * to the bit after the half significand.  In all other cases, we do.
     */
    if ((d_sig & '000007ffffffffff'.bigInt) != '0000020000000000'.bigInt) {
      d_sig += '0000020000000000'.bigInt;
    }
  } else {
    d_sig += '0000020000000000'.bigInt;
  }
  h_sig = (d_sig >> 42).toInt() & 0xFFFF;

/*
     * If the rounding causes a bit to spill into h_exp, it will
     * increment h_exp by one and h_sig will be zero.  This is the
     * correct result.  h_exp may increment to 15, at greatest, in
     * which case the result overflows to a signed inf.
     */
  if (NPY_HALF_GENERATE_OVERFLOW) {
    h_sig += h_exp;
    if (h_sig == 0x7c00) {
      throw IllegalArgumentException('npy_set_floatstatus_overflow');
    }
    return h_sgn + h_sig;
  } else {
    return h_sgn + h_exp + h_sig;
  }
}

BigInt npy_halfbits_to_doublebits(int h) {
  int h_exp, h_sig;
  BigInt d_sgn, d_exp, d_sig;

  h_exp = (h & 0x7c00);
  d_sgn = (BigInt.from(h) & BigInt.from(0x8000)) << 48;

  switch (h_exp) {
    case 0x0000:
      /* 0 or subnormal */
      h_sig = (h & 0x03ff);
/* Signed zero */
      if (h_sig == 0) {
        return d_sgn;
      }
/* Subnormal */
      h_sig <<= 1;
      while ((h_sig & 0x0400) == 0) {
        h_sig <<= 1;
        h_exp++;
      }
      d_exp = (BigInt.from(1023 - 15 - h_exp)) << 52;
      d_sig = (BigInt.from(h_sig & 0x03ff)) << 42;
      return d_sgn + d_exp + d_sig;
    case 0x7c00:
      /* inf or NaN */
/* All-ones exponent and a copy of the significand */
      return d_sgn + '7ff0000000000000'.bigInt + ((BigInt.from(h & 0x03ff)) << 42);
    default:
      /* normalized */
/* Just need to adjust the exponent and shift */
      return d_sgn + ((BigInt.from(h & 0x7fff) + BigInt.from(0xfc000)) << 42);
  }
}
