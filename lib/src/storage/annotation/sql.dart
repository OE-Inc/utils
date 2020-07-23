

import 'dart:convert';
import 'dart:typed_data';

import '../../utils.dart';

const _TAG = "annotation/sql";

typedef ToSqlColumn<SQL_TYPE, VAL_TYPE> = SQL_TYPE Function(String key, VAL_TYPE col);
typedef FromSqlColumn<SQL_TYPE, VAL_TYPE> = VAL_TYPE Function(String key, SQL_TYPE col);

/// should implement CLASS.instance() constructor.
abstract class SqlSerializable<SQL_TYPE, CLASS> {
  /// called before saving to database, transfer memory object to db type.
  SQL_TYPE toSave();
  /// called after loading from database, and transfer to a memory object.
  /// NOTE: could returns a new instance if old instance is const.
  CLASS fromSave(SQL_TYPE col);

  const SqlSerializable();
}

class SqlSerializer<VAL_TYPE, SQL_TYPE> {
  /// called before saving to database, transfer memory object to db type.
  SQL_TYPE Function(String key, VAL_TYPE col) toSave;
  /// called after loading from database, and transfer to a memory object.
  VAL_TYPE Function(String key, SQL_TYPE col) fromSave;

  SqlSerializer({ this.toSave, this.fromSave });
}

/// Sql Column transformer
enum SqlTransformer {
  /// save Uint8List columns as hexString.
  hex,
  /// save Uint8List columns as base64 string.
  base64,
  /// call toJson/fromJson.
  json,

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

  final String    table;
  final String    name;
  final String    type;

  /// raw field name
  final String    field;
  /// raw field type
  final String    fieldType;
  /// field saving memory type
  final String    finalType;

  final VAL_TYPE  defaultValue;
  final bool      nullable;

  /** // ignore: slash_for_doc_comments
    default to null, will auto detect using:

    <pre>
     TYPE               |  SqlColumnTransformer   |  SQL TYPE
    ----------------------------------------------------------------------
     SqlSerializable    => sqlSerializable        => auto detect next
     Uint8List          => binary                 => BLOB
     int,               => --                     => BIGINT
     num                => --                     => REAL/DECIMAL
     String             => --                     => TEXT
     Map/List           => --                     => TEXT
     JsonSerializable   => json                   => TEXT
     </pre>
   */
  final SqlTransformer                      transformer;

  /// Should be set by builder not manual code ONLY!!!
  final SqlSerializer<VAL_TYPE, SQL_TYPE>   transfer;

  const SqlColumnDef({
    this.table,
    this.name,
    this.type,

    this.field,
    this.fieldType,
    this.finalType,

    this.defaultValue,
    this.nullable = DEFAULT_NULLABLE,
    this.transformer,
    this.transfer,
  });

  dynamic fromSql(var col) {
    if (col == null)
      return col;

    if (fieldType == '$bool')
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

      case SqlTransformer.sqlSerializable: return transfer.fromSave(name, col); break;

      // case SqlTransformer.enumerate: return val.fromSave(null, val); break;

      default: throw IllegalArgumentException("not support SqlTransformer: $transformer.");
    }
  }

  dynamic toSql(var val) {
    if (transformer == null || val == null)
      return val;

    switch (transformer) {
      case SqlTransformer.json: return jsonEncode(val);
      case SqlTransformer.hex: return (val as Uint8List).hexString();
      case SqlTransformer.base64: return base64Encode(val);

      case SqlTransformer.sqlSerializable: return (val as SqlSerializable).toSave();

      // case SqlTransformer.enumerate: return transfer.toSave(); break;

      default: throw IllegalArgumentException("not support SqlTransformer: $transformer.");
    }
  }
}


class SqlTableDef {
  final String          tableName;
  /// primary keys in sql.
  final List<String>    primaryKeys;

  /// collectionKeyCount == 1, it's a one key map, eg: table.get(key);
  /// collectionKeyCount == 2, it's a two key map, eg: table.get(key1, key2);
  /// not support larger size.
  final int             collectionKeyCount;

  const SqlTableDef(this.tableName, this.primaryKeys, this.collectionKeyCount)
    : assert(tableName != null),
      assert(tableName.length > 0),
      assert(collectionKeyCount <= 2)
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
