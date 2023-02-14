

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:utils/util/enum.dart';

import '../../utils.dart';

const _TAG = "annotation/sql";

typedef ToSqlColumn<SQL_TYPE, VAL_TYPE> = SQL_TYPE Function(String key, VAL_TYPE col);
typedef FromSqlColumn<SQL_TYPE, VAL_TYPE> = VAL_TYPE Function(String key, SQL_TYPE col);

/// should implement CLASS.instance() constructor.
abstract class SqlSerializable<SQL_TYPE, CLASS> {
  /// called before saving to database, transfer memory object to db type.
  SQL_TYPE toSave();

  dynamic toJson() {
    var val = toSave();
    if (val is Uint8List) return base64Encode(val);
    else if (val is Enum) return val.name;
    return val;
  }

  /// called after loading from database, and transfer to a memory object.
  /// NOTE: could returns a new instance if old instance is const.
  CLASS fromSave(SQL_TYPE col);

  COL_CLASS fromJsonLazy<COL_CLASS>(String key, dynamic col, Map<String, dynamic> m) {
    throw UnimplementedError('Should implement fromJsonLazy for: { key: $key, col: $col, }, map: $m.');
  }

  CLASS fromJson(dynamic col) {
    if (SQL_TYPE == Uint8List) {
      col = base64Decode(col);
    } else if (this is Enum) {
      throw UnimplementedError('Enum class should implement fromJson().');
    }

    return fromSave(col);
  }

  const SqlSerializable();
}

class SqlSerializer<VAL_TYPE, SQL_TYPE> {
  /// called before saving to database, transfer memory object to db type.
  SQL_TYPE Function(String key, VAL_TYPE col, { bool? toJson })? toSave;
  /// called after loading from database, and transfer to a memory object.
  VAL_TYPE Function(String key, dynamic col, { bool fromJson, }) fromSave;

  SqlSerializer({ this.toSave, required this.fromSave });
}

/// Sql Column transformer
enum SqlTransformer {
  /// save Uint8List columns as hexString.
  hex,
  /// save Uint8List columns as base64 string.
  base64,
  /// call toJson/fromJson.
  json,
  /// int64 column type TEXT, but as String for low lib.
  int64,
  /// BigInt column type TEXT, but as String for low lib.
  bigint,

  /// the column should implement SqlSerializable
  sqlSerializable,

  // use the SqlColumnDef.transfer to do transfer.
  // enumerate,

  /// use the raw sqflite support.
  raw,
}

class IgnoredColumn {
  const IgnoredColumn();
}

class StampColumn {
  const StampColumn();
}

class SqlColumnDef<SQL_TYPE, VAL_TYPE> {
  static const DEFAULT_NULLABLE = false;

  final String?   table;
  final String?   name;
  final String?   oldName;
  final String?   type;

  /// raw field name
  final String?   field;
  /// raw field type
  final String?   fieldType;
  /// field saving memory type
  final String?   finalType;

  final VAL_TYPE? defaultValue;
  final bool      nullable;

  final bool?     lazyRestore;

  /** // ignore: slash_for_doc_comments
    default to null, will auto detect using:

    <pre>
     TYPE               |  SqlColumnTransformer   |  SQL TYPE
    ----------------------------------------------------------------------
     SqlSerializable    => sqlSerializable        => auto detect next
     Uint8List          => binary                 => BLOB
     int                => --                     => BIGINT
     Int64/BigInt       => --                     => TEXT
     num                => --                     => REAL/DECIMAL
     String             => --                     => TEXT
     Map/List           => --                     => TEXT
     JsonSerializable   => json                   => TEXT
     </pre>
   */
  final SqlTransformer?                     transformer;

  /// Should be set by builder not manual code ONLY!!!
  final SqlSerializer<VAL_TYPE, SQL_TYPE>?  transfer;

  const SqlColumnDef({
    this.table,
    this.name,
    this.oldName,
    this.type,

    this.field,
    this.fieldType,
    this.finalType,

    this.defaultValue,
    this.nullable = DEFAULT_NULLABLE,
    this.transformer,
    this.transfer,

    this.lazyRestore,
  });

  dynamic get typeDefaultValue {
    switch (type) {
      case "BLOB":
        return "";

      case "BIGINT":
      case "REAL":
      case "INTEGER":
      case "DECIMAL":
        return 0;

      case "TEXT":
        return "";

      default:
        throw UnsupportedError('not support default value for column type: $type.');
    }
  }

  dynamic fromSql(var val) {
    if (lazyRestore == true)
      return val;

    try {
      return _fromSql(val);
    } catch (e) {
      print('[ERROR] $table fromSql error field: $field, type: $type/$transformer, fieldType: $fieldType, val(${val.runtimeType}): $val\n  error: ${errorMsg(e)}');
      rethrow;
    }
  }

  dynamic _fromSql(var col) {
    if (col == null)
      return col;

    if (fieldType == 'bool')
      return col == 1;

    if (transformer == null)
      return col;

    // print('fromSql: ${col is Uint8List ? col.hexString() : col}(type: ${col.runtimeType}), of: $table.$name, type: $type, fieldType: $fieldType, finalType: $finalType.');

    switch (transformer) {
      case SqlTransformer.json: {
        var r = jsonDecode(col);
        if (r is List && r.isEmpty) return null;
        else if (r is Map && r.isEmpty) return null;
        else return r;
      } break;
      case SqlTransformer.hex: return ByteUtils.fromHexString(col);
      case SqlTransformer.base64: return base64Decode(col);
      case SqlTransformer.int64: return col is Uint8List ? Int64.parseHex(col.hexString(withOx: false)) : Int64.parseInt('$col');
      case SqlTransformer.bigint: return BigInt.parse('$col');

      case SqlTransformer.sqlSerializable: return transfer!.fromSave(name!, col); break;

      // case SqlTransformer.enumerate: return val.fromSave(null, val); break;

      default: throw IllegalArgumentException("not support sql SqlTransformer: $transformer, field: $field, fieldType: $fieldType, val: $col.");
    }
  }

  dynamic toSql(var val) {
    if (val == null)
      return val;

    if (fieldType == 'bool')
      return val == true ? 1 : 0;

    if (transformer == null)
      return val;

    switch (transformer) {
      case SqlTransformer.json: return jsonEncode(val);
      case SqlTransformer.hex: return (val as Uint8List).hexString();
      case SqlTransformer.base64: return base64Encode(val);
      case SqlTransformer.int64: return val.toString();
      case SqlTransformer.bigint: return val.toString();

      case SqlTransformer.sqlSerializable: return (val as SqlSerializable).toSave();

      // case SqlTransformer.enumerate: return transfer.toSave(); break;

      default: throw IllegalArgumentException("not support sql SqlTransformer: $transformer, field: $field, fieldType: $fieldType, val: $val.");
    }
  }


  dynamic fromJson(var val) {
    if (lazyRestore == true)
      return val;

    try {
      return _fromJson(val);
    } catch (e) {
      print('[ERROR] $table fromJson error field: $field, type: $type/$transformer, fieldType: $fieldType, val(${val.runtimeType}): $val\n  error: ${errorMsg(e)}');
      rethrow;
    }
  }

  dynamic _fromJson(var val) {
    if (val == null)
      return val;

    if (fieldType == 'Uint8List') {
      // return val = base64Decode(val);
      // TODO: should transfer
      return val = val is String ? base64Decode(val) : Uint8List.fromList((val as List).map((v) => v as int).toList());
    }

    if (transformer == null)
      return val;

    switch (transformer) {
      case SqlTransformer.json: {
        // TODO: type transfer.
        if (fieldType!.startsWith('Map<String, dynamic>')) return Map<String, dynamic>.from(val);
        else if (fieldType!.startsWith('List')) {
          if (fieldType == 'List<int>') return List<int>.from(val);
          if (fieldType == 'List<double>') return List<double>.from(val);
          else if (fieldType == 'List<String>') return List<String>.from(val);
          else if (fieldType == 'List<dynamic>') return List.from(val);
        } else return val;
      } break;
      case SqlTransformer.hex: return ByteUtils.fromHexString(val);
      case SqlTransformer.base64: return base64Decode(val);
      case SqlTransformer.int64: return val is Uint8List ? Int64.parseHex(val.hexString(withOx: false)) : Int64.parseInt('$val');
      case SqlTransformer.bigint: return BigInt.parse('$val');

      case SqlTransformer.sqlSerializable: return transfer!.fromSave(name!, val, fromJson: true);

      default: throw IllegalArgumentException("not support json SqlTransformer: $transformer, field: $field, fieldType: $fieldType, val: $val.");
    }
  }

  dynamic toJson(var val) {
    try {
      return _toJson(val);
    } catch (e) {
      print('[ERROR] $table toJson error field: $field, type: $type/$transformer, fieldType: $fieldType, val(${val.runtimeType}): $val.');
      rethrow;
    }
  }

  dynamic _toJson(var val) {
    if (val == null)
      return val;

    if (fieldType == 'Uint8List') {
      return base64Encode(val);
    }

    if (val is Enum) {
      // TODO: should use name, not value?
      return val.value is int ? val.value : val.name;
    }

    if (transformer == null)
      return val;

    switch (transformer) {
      case SqlTransformer.json: return val;
      case SqlTransformer.hex: return (val as Uint8List).hexString();
      case SqlTransformer.base64: return base64Encode(val);
      case SqlTransformer.int64: return val.toString();
      case SqlTransformer.bigint: return val.toString();

      case SqlTransformer.sqlSerializable: return (val as SqlSerializable).toJson();

      default: throw IllegalArgumentException("not support json SqlTransformer: $transformer, field: $field, fieldType: $fieldType, val: $val.");
    }
  }
}


class SqlTableDef {
  final String          tableName;
  /// primary keys in sql.
  final List<String>    primaryKeys;

  /// collectionKeyCount == 1, it's a one key map, eg: table.get(key);
  /// collectionKeyCount == 2, it's a two key map, eg: table.get(key1, key2);
  /// collectionKeyCount == 3, it's a 3 key map, eg: table.get(key1, key2, key3);
  /// not support larger size.
  final int             collectionKeyCount;
  final Map<String, List<String>>?   indexes, uniqueIndexes;

  const SqlTableDef(this.tableName, this.primaryKeys, this.collectionKeyCount, { this.indexes, this.uniqueIndexes, })
    : assert(tableName != null),
      assert(tableName.length > 0),
      assert(collectionKeyCount <= 3)
  ;

  final checked = const [false];

  void check() {
    if (checked[0])
      return;

    checked[0] = true;
    if (collectionKeyCount > primaryKeys.length)
      print("$_TAG: collectionKeyCount($collectionKeyCount) should less than primaryKeys size(${primaryKeys.length}): $primaryKeys.${StackTrace.current}");
  }
}
