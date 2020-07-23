

import 'package:utils/src/enum.dart';

import 'common.dart';

// Code usage:
// @Enum(int)
class _ENUM_CLASS_DEF__ {
  static int
  STATIC_FIELD_NAME__;
}

class ENUM_TYPE__ extends FIELD_TYPE__{ }
const ENUM_FIELD_NAME__ = '__DEL__';
class Log {
  static void e(String tag, String msg) { }
}

// GENERATION START

class CLASS_NAME__ extends Enum<CLASS_NAME__, ENUM_TYPE__> {
  static const CLASS_NAME__ STATIC_FIELD_NAME__ = CLASS_NAME__(STATIC_FIELD_VALUE__, "STATIC_FIELD_NAME__", field: ENUM_FIELD_NAME__ );

  const CLASS_NAME__(ENUM_TYPE__ value, String name, { String field }) : super(value, name, field: field);

  const CLASS_NAME__.instance() : super(null, null);

  static final Map<String, CLASS_NAME__> _stringToVal = {
    "STATIC_FIELD_NAME__": STATIC_FIELD_NAME__,
  };

  static final Map<ENUM_TYPE__, CLASS_NAME__> _valToString = {
    STATIC_FIELD_VALUE__: STATIC_FIELD_NAME__,
  };

  static Map<String, CLASS_NAME__> get stringMap => _stringToVal;
  static Map<ENUM_TYPE__, CLASS_NAME__> get valueMap => _valToString;

  static List<String> get keys => _stringToVal.keys;
  static List<ENUM_TYPE__> get values => _valToString.keys;

  static String getString(ENUM_TYPE__ e) {
    return _valToString[e]?.name;
  }

  static String getField(ENUM_TYPE__ e) {
    return _valToString[e]?.field;
  }

  static ENUM_TYPE__ getValue(String e) {
    return _stringToVal[e]?.value;
  }

  @override
  CLASS_NAME__ fromSave(ENUM_TYPE__ col) => valueMap[col];

  factory CLASS_NAME__.fromValue(ENUM_TYPE__ val) {
    var v = valueMap[val];

    if (v == null) {
      Log.e('CLASS_NAME__', 'fromValue of invalid: $val.');
      v = CLASS_NAME__(val, null);
    }

    return v;
  }
}

// GENERATION END

