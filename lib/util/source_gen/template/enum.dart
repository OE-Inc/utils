
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

// ignore_for_file: non_constant_identifier_names, camel_case_extensions, camel_case_types, unused_element, unused_field


import 'package:utils/util/enum.dart';

import 'common.dart';

// Code usage:
// @Enum(int)
class _ENUM_CLASS_DEF__ {
  static late int
  STATIC_FIELD_NAME__;
}

class ENUM_TYPE__{ const ENUM_TYPE__(); }
const ENUM_FIELD_NAME__ = '__DEL__';
class Log {
  static void e(String tag, String Function() msg) { }
}

/*
// GENERATION START

class CLASS_NAME__ extends Enum<CLASS_NAME__, ENUM_TYPE__> {
  static const CLASS_NAME__ STATIC_FIELD_NAME__ = CLASS_NAME__(STATIC_FIELD_VALUE__, "STATIC_FIELD_NAME__", field: ENUM_FIELD_NAME__ );

  const CLASS_NAME__(ENUM_TYPE__ value, String? name, { String? field }) : super(value, name, field: field);

  CLASS_NAME__.instance() : super(_defaultValue, null);

  static ENUM_TYPE__? _defaultValue_;
  static ENUM_TYPE__ get _defaultValue {
    if (_defaultValue_ != null) return _defaultValue_!;

    for (var kv in stringMap.entries) {
      var k = kv.key.toLowerCase();
      if (k == 'invalid' || k == 'unknown') return _defaultValue_ = kv.value.value;
    }

    for (var kv in valueMap.entries) {
      var v = kv.value;
      if (v == -1) return _defaultValue_ = kv.value.value;
    }

    return valueMap.keys.last;
  }

  static final Map<String, CLASS_NAME__> _stringToVal = {
    "STATIC_FIELD_NAME__": STATIC_FIELD_NAME__,
  };

  static final Map<ENUM_TYPE__, CLASS_NAME__> _valToString = {
    STATIC_FIELD_VALUE__: STATIC_FIELD_NAME__,
  };

  static Map<String, CLASS_NAME__> get stringMap => _stringToVal;
  static Map<ENUM_TYPE__, CLASS_NAME__> get valueMap => _valToString;

  static Iterable<String> get keys => _stringToVal.keys;
  static Iterable<ENUM_TYPE__> get values => _valToString.keys;
  static Iterable<CLASS_NAME__> get enums => _valToString.values;

  static String? getString(ENUM_TYPE__ e) {
    return _valToString[e]?.name;
  }

  static String? getField(ENUM_TYPE__ e) {
    return _valToString[e]?.field;
  }

  static ENUM_TYPE__? getValue(String e) {
    return _stringToVal[e]?.value;
  }

  @override
  CLASS_NAME__ fromSave(ENUM_TYPE__ col) => valueMap[col]!;

  @override
  CLASS_NAME__ fromJson(col) => stringMap[col] ?? valueMap[col] ?? (col is CLASS_NAME__ ? col : CLASS_NAME__.fromValue(col));

  static CLASS_NAME__ fromJsonVal(col) => stringMap[col] ?? valueMap[col] ?? (col is CLASS_NAME__ ? col : CLASS_NAME__.fromValue(col));

  static CLASS_NAME__? fromStringVal(String val, { bool allowNull = false, }) => fromStringValNullable(val, allowNull: false)!;

  static CLASS_NAME__? fromStringValNullable(String? val, { bool allowNull = true, }) {
    var v = stringMap[val];

    if (v == null) {
      Log.e('CLASS_NAME__', () => 'fromString of invalid: $val.');
      if (!allowNull)
        v = CLASS_NAME__(_defaultValue, val);
    }

    return v;
  }

  static CLASS_NAME__ fromValue(ENUM_TYPE__ val, { bool allowNull = false, }) => fromValueNullable(val, allowNull: false)!;

  static CLASS_NAME__? fromValueNullable(ENUM_TYPE__? val, { bool allowNull = true, }) {
    var v = valueMap[val];

    if (v == null) {
      Log.e('CLASS_NAME__', () => 'fromValue of invalid: $val.');
      if (!allowNull)
        v = CLASS_NAME__(val!, null);
    }

    return v;
  }
}

// GENERATION END

// */
