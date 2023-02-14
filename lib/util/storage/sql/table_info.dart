
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:typed_data';

import 'package:utils/util/storage/annotation/sql.dart';

import '../../error.dart';
import '../../pair.dart';
import '../../utils.dart';

class SqlWhereItem {
  static const
    OP_LARGER_EQUAL = ">=",
    OP_LARGER       = ">",
    OP_LESS_EQUAL   = "<=",
    OP_LESS         = "<",
    OP_NOT_EQUAL    = "!=",
    OP_EQUAL        = "=",
    OP_LIKE         = "LIKE"
  ;

  static const SUPPORT_OP = { OP_LARGER_EQUAL, OP_LARGER, OP_LESS_EQUAL, OP_LESS, OP_NOT_EQUAL, OP_EQUAL, OP_LIKE, };

  /// support: [ ">=", ">", "<", "<=", "!=" ]
  String          op;
  String          col;
  dynamic         value;

  String?         escape;

  SqlWhereItem(this.op, this.col, this.value, { this.escape });

  @override
  String toString() {
    return escape != null
        ? "($col $op $value ESCAPE $escape)"
        : "($col $op $value)";
  }
}

class SqlWhereObj {

  int?      offset, limit;

  List<List<dynamic>>?    groupBys;
  List<List<dynamic>>?    orderBys;

  List<SqlWhereItem>?     where;
  bool                    whereOr = false;
  List<String>?           columns;
  String?                 distinct;


  String get cacheString {
    var str = "";

    if (columns != null) str += "COLUMNS $columns ";
    if (whereOr) str += "WHERE_OR ";
    if (distinct != null) str += "DISTINCT $distinct ";
    if (where != null) str += "WHERE $where ";
    if (orderBys != null) str += "ORDER_BY $orderBys ";
    if (groupBys != null) str += "GROUP_BY $groupBys ";
    if (offset != null) str += "OFFSET $offset ";
    if (limit != null) str += "LIMIT $limit ";

    return str;
  }

  bool isEmpty(Set<String> pk) {
    var empty = offset == null && limit == null
        && groupBys == null && orderBys == null
        && noCkNormalWhere(pk)
        && columns == null
        && distinct == null
    ;
    // print('isEmpty, pk: $pk, where: $where(${noCkNormalWhere(pk)}), empty: $empty.');
    return empty;
  }

  bool noCkNormalWhere(Set<String> pk) => where == null || where!.isEmpty || !where!.any((c) => !pk.contains(c.col));

  void first() { limit = 1; }

  void orderBy(String key, [ bool ascending = true ]) {
    orderBys = orderBys ?? [];

    orderBys!.add([key, ascending == false ? "DESC" : "ASC"]);
  }

  void groupBy(String key, [ bool ascending = true ]) {
    groupBys = groupBys ?? [];

    groupBys!.add([key, ascending == false ? "DESC" : "ASC"]);
  }

  /// op: [ ">=", ">", "<", "<=", "!=", "LIKE" ], should use SqlWhereItem.OP_XXXXXX.
  void compared(String op, String col, dynamic val, { String? escape }) {
    if (!SqlWhereItem.SUPPORT_OP.contains(op))
      throw UnsupportedError("op not support: $op, should be: ${SqlWhereItem.SUPPORT_OP}");

    if (op == SqlWhereItem.OP_LIKE && val is! String)
      throw IllegalArgumentException("op LIKE should always use a string param, not: $val.");

    where = where ?? [];
    where!.add(SqlWhereItem(op, col, val, escape: escape));
  }

  void equal(String col, dynamic val) {
    compared(SqlWhereItem.OP_EQUAL, col, val);
  }

  void like(String col, String val, { String? escape }) {
    compared(SqlWhereItem.OP_LIKE, col, val, escape: escape);
  }

  Triple<String, List<Object>, List> finalWhere(SqlTableInfo tableInfo, { bool withWhereWord = true, }) {
    var str = '';
    List<Object> args = [];
    List argNames = [];

    if (where != null && where!.isNotEmpty) {
      if (withWhereWord)
        str += 'WHERE ';

      str += where!.map((item) {
        var val = item.op == SqlWhereItem.OP_LIKE
            ? item.value
            : tableInfo.columns[item.col]!.toSql(item.value);

        if (val is Uint8List) {
          return "${item.col} ${item.op} x'${val.hexString(withOx: false)}'";
        } else {
          args.add(val);
          argNames.add(item.col);
          if (item.escape != null) {
            argNames.add('${item.col}-ESCAPE');
            args.add(item.escape!);
          }

          return item.escape != null
              ? '${item.col} ${item.op} ? ESCAPE ?'
              : '${item.col} ${item.op} ?';
        }
      })
          .join(whereOr ? " OR " : ' AND ');
    }

    if (groupBys != null && groupBys!.isNotEmpty)
      str += ' GROUP BY ' + groupBys!.map((g) => '${g[0]} ${g[1]}').join(' ,');

    if (orderBys != null && orderBys!.isNotEmpty)
      str += ' ORDER BY ' + orderBys!.map((o) => '${o[0]} ${o[1]}').join(' ,');

    if (limit != null && limit! > 0) {
      if (offset != null && offset! > 0)
        str += ' LIMIT $offset $limit';
      else
        str += ' LIMIT $limit';
    }

    return Triple(str, args, argNames);
  }

  @override
  String toString() {
    return "$runtimeType { offset: $offset, limit: $limit, columns: $columns, where: $where, distinct: $distinct, groupBys: $groupBys, orderBys: $orderBys, }";
  }

}

abstract class SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> {
  late  String                        tableName;

  late  Map<String, SqlColumnDef>     columns;
  late  List<SqlColumnDef>            lazyColumns;
  late  Map<String, SqlColumnDef>     colFields = { };

  /// include ckd
  late  Map<String, SqlColumnDef>     pkd;
  late  List<String>                  pk, pkNoCk;
  Map<String, List<String>>?          indexes, uniqueIndexes;
  late  Set<String>                   pkNoCkSet;
  late  Set<String>                   pkSet;

  late  Map<String, SqlColumnDef>     ckd;
  late  List<String>                  ck;

  /// not include pk
  late  Map<String, SqlColumnDef>     nkd;
  /// not include pk[]
  late  List<String>                  nk;

  late  Map<String, SqlColumnDef>     transformers;
  late  Map<String, SqlColumnDef>     jsonTransformers;
  late  VALUE_TYPE_PARTIAL            template;
  late  bool                          existLazy = false;

  bool get                            hasIndexes => indexes?.isNotEmpty == true || uniqueIndexes?.isNotEmpty == true;

  SqlTableInfo(this.tableName, this.pk, int ckCount, this.template, { this.indexes, this.uniqueIndexes, }) {
    columns = makeColumnDefine();
    for (var col in columns.values) {
      colFields[col.field!] = col;
    }

    for (var k in pk) {
      if (!columns.containsKey(k))
        throw IllegalArgumentException('Table `$tableName` not exist primary key: $k.');
    }

    var idxMap = indexes;
    if (idxMap != null && idxMap.isNotEmpty) {
      for (var index in idxMap.keys) {
        var keys = idxMap[index]!;

        for (var k in keys)
          if (!columns.containsKey(k))
            throw IllegalArgumentException('Table `$tableName` not exist index($index) key: $k.');
      }
    }

    var uIdxMap = indexes;
    if (uIdxMap != null && uIdxMap.isNotEmpty) {
      for (var index in uIdxMap.keys) {
        var keys = uIdxMap[index]!;

        for (var k in keys)
          if (!columns.containsKey(k))
            throw IllegalArgumentException('Table `$tableName` not exist unique index($index) key: $k.');
      }
    }

    if (ckCount < 1 || ckCount > pk.length)
      throw IllegalArgumentException('Table `$tableName` ckCount($ckCount) should inside: [1, ${pk.length}]');

    pkNoCk = pk.sublist(0, pk.length - ckCount);

    ck = pk.sublist(pk.length - ckCount);
    nk = columns.keys.toList()..removeWhere((k) => pk.contains(k));

    this.pkd = {...this.columns}..removeWhere((k, v) => !pk.contains(k));
    this.ckd = {...this.columns}..removeWhere((k, v) => !ck.contains(k));
    this.nkd = {...this.columns}..removeWhere((k, v) => !nk.contains(k));

    this.transformers = {...this.columns}..removeWhere((k, v)
      => (v.transformer == null || v.transformer == SqlTransformer.raw)
          && v.fieldType != 'bool');

    this.jsonTransformers = {...this.columns}..removeWhere((k, v)
      => (v.transformer == null || v.transformer == SqlTransformer.raw)
        && v.fieldType != 'Uint8List');

    pkNoCkSet = pkNoCk.toSet();
    pkSet = pk.toSet();

    lazyColumns = this.columns.values.where((e) => e.lazyRestore == true).toList();
    existLazy = lazyColumns.isNotEmpty;
  }

  Map<String, SqlColumnDef> makeColumnDefine();

  fillTemplateKeys(VALUE_TYPE_PARTIAL part, bool withPk, bool withCk);

  VALUE_TYPE fromSql(Map<String, dynamic> cols);
  Map<String, dynamic> toSql(VALUE_TYPE val);

  VALUE_TYPE fromSqlTransfer(Map<String, dynamic> cols) {
    return fromSql(cols);
  }

  Map<String, dynamic> fromSqlTransferMap(Map<String, dynamic> cols, { bool fromJson = false, bool noCopy = false, }) {
    var transformers = fromJson ? jsonTransformers : this.transformers;

    if (transformers.isEmpty)
      return cols;

    if (noCopy || cols.length > transformers.length) {
      if (!noCopy) {
        cols = Map.from(cols);
      }

      for (var key in transformers.keys) {
        var trans = transformers[key]!;
        var val = cols[key];
        if (val == null)
          continue;
        cols[key] = fromJson ? trans.fromJson(val) : trans.fromSql(val);
      }
    } else {
      cols = Map.from(cols);
      for (var key in cols.keys) {
        var trans = transformers[key];
        if (trans == null)
          continue;

        var val = cols[key];
        if (val == null)
          continue;
        cols[key] = fromJson ? trans.fromJson(val) : trans.fromSql(val);
      }
    }

    return cols;
  }

  Map<String, dynamic> toSqlTransfer(VALUE_TYPE val, { bool? excludePk, bool toJson = false, }) {
    return toSqlTransferMap(toSql(val), excludePk: excludePk, toJson: toJson);
  }

  Map<String, dynamic> toSqlTransferMap(Map<String, dynamic> cols, { bool? excludePk, bool toJson = false, }) {
    var transformers = toJson ? jsonTransformers : this.transformers;

    // print('transformers(toJson: $toJson): $transformers.');
    if (transformers.isEmpty)
      return cols;

    if (excludePk == true) {
      for (var k in pk)
        cols.remove(k);
    }

    for (var key in transformers.keys) {
      var val = cols[key];
      if (val == null)
        continue;

      var trans = transformers[key]!;
      cols[key] = toJson ? trans.toJson(val) : trans.toSql(val);
    }

    return cols;
  }

  /// pk: primary key.
  /// ck: collection key.
  /// nk: normal key, exclude ck/pk.
  /// for template, should only use pk.
  SqlWhereObj getWhere(VALUE_TYPE_PARTIAL part, bool withPk, bool excludeCk, bool withNk, { SqlWhereObj? where, });

  VALUE_TYPE_PARTIAL toPartial(VALUE_TYPE part);

  /// all columns compared.
  SqlWhereObj simpleWhere(VALUE_TYPE_PARTIAL part, { bool? withPk = true, bool? excludeCk = false, bool? withNk = true, SqlWhereObj? where, }) {
    return getWhere(part, withPk ?? true, excludeCk ?? false, withNk ?? true, where: where);
  }

  String tableDefine() {
    var cols = columns.values.map((c) {
      return '`${c.name}` ${c.type} ${c.nullable ? '' : 'NOT NULL'} ${c.defaultValue != null ? 'DEFAULT ${c.defaultValue}' : ''}';
    }).join(',');

    return pk.isEmpty
      ? '$cols'
      : '$cols, PRIMARY KEY(${pk.map((k) => '`$k`').join(',')})'
    ;
  }

}
