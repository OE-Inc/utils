
import 'dart:convert';
import 'dart:typed_data';

import 'package:utils/src/storage/annotation/sql.dart';
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

  SqlWhereItem(this.op, this.col, this.value);

}

class SqlWhereObj {

  int       offset, limit;

  List<List<dynamic>>     groupBys;
  List<List<dynamic>>     orderBys;

  List<SqlWhereItem>      where;
  List<String>            columns;
  String                  distinct;

  void first() { limit = 1; }

  void orderBy(String key, [ bool ascending = true ]) {
    orderBys = orderBys ?? [];

    orderBys.add([key, ascending == false ? "DESC" : "ASC"]);
  }

  void groupBy(String key, [ bool ascending = true ]) {
    groupBys = groupBys ?? [];

    groupBys.add([key, ascending == false ? "DESC" : "ASC"]);
  }

  /// op: [ ">=", ">", "<", "<=", "!=", "LIKE" ], should use SqlWhereItem.OP_XXXXXX.
  void compared(String op, String col, dynamic val) {
    if (!SqlWhereItem.SUPPORT_OP.contains(op))
      throw UnsupportedError("op not support: $op, should be: ${SqlWhereItem.SUPPORT_OP}");

    if (op == SqlWhereItem.OP_LIKE && val is! String)
      throw IllegalArgumentException("op LIKE should always use a string param, not: $val.");

    where = where ?? [];
    var old = where.indexWhere((w) => w.col == col);

    if (old >= 0) {
      where.removeAt(old);
      where.insert(old, SqlWhereItem(op, col, val));
    } else {
      where.add(SqlWhereItem(op, col, val));
    }
  }

  void like(String op, String col, String val) {
    compared(op, col, val);
  }

  Pair<String, List> finalWhere(SqlTableInfo tableInfo, { bool withWhereWord = true, }) {
    var str = '';
    List args = [];

    if (where != null && where.isNotEmpty) {
      if (withWhereWord)
        str += 'WHERE ';

      str += where.map((item) {
        var val = tableInfo.columns[item.col].toSql(item.value);

        if (val is Uint8List) {
          return "${item.col} ${item.op} x'${val.hexString(withOx: false)}'";
        } else {
          args.add(val);
          return '${item.col} ${item.op} ?';
        }
      })
          .join(' AND ');
    }

    if (groupBys != null && groupBys.isNotEmpty)
      str += ' GROUP BY ' + groupBys.map((g) => '${g[0]} ${g[1]}').join(' ,');

    if (orderBys != null && orderBys.isNotEmpty)
      str += ' ORDER BY ' + orderBys.map((o) => '${o[0]} ${o[1]}').join(' ,');

    if (limit != null && limit > 0) {
      if (offset != null && offset > 0)
        str += ' LIMIT $offset $limit';
      else
        str += ' LIMIT $limit';
    }

    return Pair(str, args);
  }

}

abstract class SqlTableInfo<VALUE_TYPE> {
  String                        tableName;

  Map<String, SqlColumnDef>     columns;
  Map<String, SqlColumnDef>     colFields = { };

  /// include ckd
  Map<String, SqlColumnDef>     pkd;
  List<String>                  pk, pkNoCk;

  Map<String, SqlColumnDef>     ckd;
  List<String>                  ck;

  /// not include pk
  Map<String, SqlColumnDef>     nkd;
  /// not include pk[]
  List<String>                  nk;

  Map<String, SqlColumnDef>     transformers;
  VALUE_TYPE                    template;

  SqlTableInfo(this.tableName, this.pk, int ckCount, this.template) {
    columns = makeColumnDefine();
    for (var col in columns.values) {
      colFields[col.field] = col;
    }

    for (var k in pk) {
      if (!columns.containsKey(k))
        throw IllegalArgumentException('Table `$tableName` not exist primary key: $k.');
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
          && v.fieldType != '$bool');
  }

  Map<String, SqlColumnDef> makeColumnDefine();

  fillTemplateKeys(VALUE_TYPE part, bool withPk, bool withCk);

  VALUE_TYPE fromSql(Map<String, dynamic> cols);
  Map<String, dynamic> toSql(VALUE_TYPE val);

  VALUE_TYPE fromSqlTransfer(Map<String, dynamic> cols) {
    return fromSql(cols);
  }

  Map<String, dynamic> fromSqlTransferMap(Map<String, dynamic> cols) {
    if (transformers.isEmpty)
      return cols;

    cols = Map.from(cols);
    for (var key in transformers.keys) {
      cols[key] = transformers[key].fromSql(cols[key]);
    }

    return cols;
  }

  Map<String, dynamic> toSqlTransfer(VALUE_TYPE val, { bool excludePk, }) {
    Map<String, dynamic> cols = toSql(val);

    print('transformers: $transformers.');
    if (transformers.isEmpty)
      return cols;

    if (excludePk == true) {
      for (var k in pk)
        cols.remove(k);
    }

    for (var key in transformers.keys) {
      cols[key] = transformers[key].toSql(cols[key]);
    }

    return cols;
  }

  /// pk: primary key.
  /// ck: collection key.
  /// nk: normal key, exclude ck/pk.
  /// for template, should only use pk.
  SqlWhereObj getWhere(VALUE_TYPE part, bool withPk, bool withCk, bool withNk, { SqlWhereObj where, });

  /// all columns compared.
  SqlWhereObj simpleWhere(VALUE_TYPE part, { bool withPk = true, bool withCk = true, bool withNk = true, SqlWhereObj where, }) {
    return getWhere(part, withPk ?? true, withCk ?? true, withNk ?? true, where: where);
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
