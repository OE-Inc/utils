
import 'dart:async';

import 'package:utils/src/error.dart';
import 'package:utils/src/simple_interface.dart';
import 'package:utils/src/storage/engine/sqlite.dart';

import '../value_cached_map.dart';
import 'annotation/sql.dart';
import 'sql/table_info.dart';



class SqlTableFuncArg<VALUE_TYPE, K1, K2, K3> {
  K1 k1;
  K2 k2;
  K3 k3;
  SqlWhereObj where;
}

abstract class SqlTableImp<VALUE_TYPE, K1, K2, K3> {
  SqlTableInfo<VALUE_TYPE>  tableInfo;
  String                    col1, col2, col3;

  String get  tableName => tableInfo.tableName;
  VALUE_TYPE get template => tableInfo.template;

  ValueCacheMap<VALUE_TYPE, VALUE_TYPE>   cached;

  SqlTableImp(this.tableInfo) {
    var ck = tableInfo.ck;
    col1 = ck[0];

    if (ck.length > 1)
      col2 = ck[1];

    if (ck.length > 2)
      col3 = ck[2];

    cached = ValueCacheMap(30 * 1000, (key, val, oldVal) async {
      var ret = await getRaw(tableInfo.getWhere(key, true, true, false));

      return ret[0];
    });
  }

  SqlWhereObj mergeWhere({K1 k1, K2 k2, K3 k3, VALUE_TYPE whereObj, SqlWhereObj where }) {
    if (whereObj != null) {
      where = tableInfo.simpleWhere(whereObj, where: where);
    }

    where = getWhere(template, true, false, false, where: where);

    if (k1 != null) where.compared(SqlWhereItem.OP_EQUAL, col1, k1);
    if (k2 != null) where.compared(SqlWhereItem.OP_EQUAL, col2, k2);
    if (k3 != null) where.compared(SqlWhereItem.OP_EQUAL, col3, k3);

    return where;
  }

  Future<List<VALUE_TYPE>> getRaw(SqlWhereObj where) async {
    return (await getRawMap(where)).map((r) => tableInfo.fromSqlTransfer(r)).toList();
  }

  Future<List<Map<String, dynamic>>> getRawMap(SqlWhereObj where);

  Future<List<VALUE_TYPE>>  get({ K1 k1, K2 k2, K3 k3, VALUE_TYPE whereObj, SqlWhereObj where, }) {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where, whereObj: whereObj);
    return getRaw(where);
  }

  Future<FIELD_TYPE>        getFiled<FIELD_TYPE>(String field, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, FIELD_TYPE fallback, }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    where.columns = [field];

    var result = await getRawMap(where);
    if (result.length > 1)
      throw IllegalArgumentException('Should always getField() for a single/primaryKey item.');

    var item = result.isNotEmpty ? tableInfo.fromSqlTransferMap(result[0]) : null;
    return item != null ? item[field]??fallback : fallback;
  }

  Future<int>         set(VALUE_TYPE val);
  Future<int>         update(VALUE_TYPE val);

  Future<int>         setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, });
  Future<int>         setFields(Map<String, dynamic> fields, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, });

  Future<bool>        containsKey({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<VALUE_TYPE>  first({ K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE fallback });

  Future<void>        invalidCache({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<bool>        contains({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<void>        forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  // Future<void>        map(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });
  // Future<void>        filter(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<List<VALUE_TYPE>>      remove({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Stream<VALUE_TYPE>            values({ K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE whereObj, });
  Stream<VALUE_TYPE>            keys(String keyCol, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<int>                   clear({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });
  Future<int>                   size({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  SqlWhereObj getWhere(VALUE_TYPE part, bool withPk, bool withCk, bool withNk, { SqlWhereObj where }) {
    return tableInfo.getWhere(part, withPk, withCk, withNk, where: where);
  }

  Future<bool> isTableExists();

  Future<void> createTable();

  Future<void> dropTable();

  Future<Map<String, SqlColumnDef>> readCols();

  clearCache() { cached.clear(); }

}

abstract class SqlTable<VALUE_TYPE, K1, K2, K3, TABLE_INFO extends SqlTableInfo<VALUE_TYPE>> {
  SqlTableImp<VALUE_TYPE, K1, K2, K3>     imp;
  TABLE_INFO builder;

  SqlTable(this.builder) {
    imp = SqlTableImpSqlite<VALUE_TYPE, K1, K2, K3>(builder);
  }

  Future<void> createTable() { return imp.createTable(); }

  Future<bool> isTableExists() { return imp.isTableExists(); }

  Future<void> dropTable() { return imp.dropTable(); }

  Future<Map<String, SqlColumnDef>> readCols() { return imp.readCols(); }
}

class SqlTable1N<K1, VALUE_TYPE, TABLE_INFO extends SqlTableInfo<VALUE_TYPE>> extends SqlTable<VALUE_TYPE, K1, void, void, TABLE_INFO> {
  SqlTable1N(TABLE_INFO builder) : super(builder);

  Future<VALUE_TYPE>  get(K1 k1, { SqlWhereObj where, VALUE_TYPE whereObj, VALUE_TYPE fallback, }) async {
    var r = await imp.get(k1: k1, where: where, whereObj: whereObj);
    if (r.length > 1)
      throw SqlException(-1, "Something is error in table defines, should never have duplicate objects.");

    return (r.isEmpty ? null : r[0]) ?? fallback;
  }

  Future<void>        set(VALUE_TYPE val) {
    return imp.set(val);
  }

  Future<FIELD_TYPE>  getField<FIELD_TYPE>(K1 k1, String field, { SqlWhereObj where, FIELD_TYPE fallback, }) {
    return imp.getFiled(field, k1: k1, where: where, fallback: fallback);
  }

  Future<int>         setFiled<FIELD_TYPE>(K1 k1, String field, FIELD_TYPE fieldVal, { SqlWhereObj where, }) {
    return imp.setField(field, fieldVal, k1: k1, where: where);
  }

  Future<int>         setFileds<FIELD_TYPE>(K1 k1, Map<String, dynamic> fields, { SqlWhereObj where, }) {
    return imp.setFields(fields, k1: k1, where: where);
  }

  Future<bool>        containsKey( K1 k1, { SqlWhereObj where }) {
    return imp.containsKey(k1: k1, where: where);
  }

  Future<VALUE_TYPE>  remove(K1 k1, { SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, where: where);
    return r.isEmpty ? null : r[0];
  }

  Future<VALUE_TYPE>  first({ K1 k1, SqlWhereObj where, VALUE_TYPE fallback }) {
    return imp.first(k1: k1, where: where, fallback: fallback);
  }

  Future<VALUE_TYPE>  invalidCache(K1 k1, { SqlWhereObj where }) {
    return imp.invalidCache(k1: k1, where: where);
  }

  Future<bool>        contains(K1 k1, { SqlWhereObj where }) {
    return imp.contains(k1: k1, where: where);
  }

  Future<void>        forEach(Callable1<VALUE_TYPE, bool> processor, { K1 k1, SqlWhereObj where }) {
    return imp.forEach(processor, k1: k1, where: where);
  }

  Stream<VALUE_TYPE>  values({ K1 k1, SqlWhereObj where, VALUE_TYPE whereObj, }) {
    return imp.values(k1: k1, where: where, whereObj: whereObj);
  }
  Stream<VALUE_TYPE>  keys(String keyCol, { K1 k1, SqlWhereObj where }) {
    return imp.keys(keyCol, k1: k1, where: where);
  }

  Future<void>                  clear({ K1 k1, SqlWhereObj where }) {
    return imp.clear(k1: k1, where: where);
  }

  Future<int>                   size({ K1 k1, SqlWhereObj where }) {
    return imp.size(k1: k1, where: where);
  }
}

class SqlTableNN<K1, K2, VALUE_TYPE, TABLE_INFO extends SqlTableInfo<VALUE_TYPE>> extends SqlTable<VALUE_TYPE, K1, K2, void, TABLE_INFO> {
  SqlTableNN(TABLE_INFO builder) : super(builder);

  Future<VALUE_TYPE>  get(K1 k1, K2 k2, { SqlWhereObj where, VALUE_TYPE whereObj, VALUE_TYPE fallback, }) async {
    var r = await imp.get(k1: k1, k2: k2, where: where, whereObj: whereObj);
    if (r.length > 1)
      throw SqlException(-1, "Something is error in table defines, should never have duplicate objects.");

    return (r.isEmpty ? null : r[0]) ?? fallback;
  }

  Future<void>        set(VALUE_TYPE val) {
    return imp.set(val);
  }

  Future<FIELD_TYPE>  getField<FIELD_TYPE>(K1 k1, K2 k2, String field, { SqlWhereObj where, FIELD_TYPE fallback, }) {
    return imp.getFiled(field, k1: k1, k2: k2, where: where, fallback: fallback);
  }

  Future<int>         setFiled<FIELD_TYPE>(K1 k1, K2 k2, String field, FIELD_TYPE fieldVal, { SqlWhereObj where, }) {
    return imp.setField(field, fieldVal, k1: k1, k2: k2, where: where);
  }

  Future<int>         setFileds<FIELD_TYPE>(K1 k1, K2 k2, Map<String, dynamic> fields, { SqlWhereObj where, }) {
    return imp.setFields(fields, k1: k1, k2: k2, where: where);
  }

  Future<bool>        containsKey( K1 k1, K2 k2, { SqlWhereObj where }) {
    return imp.containsKey(k1: k1, k2: k2, where: where);
  }

  Future<VALUE_TYPE>  remove(K1 k1, K2 k2, { SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, k2: k2, where: where);
    return r.isEmpty ? null : r[0];
  }

  Future<VALUE_TYPE>  first({ K1 k1, K2 k2, SqlWhereObj where, VALUE_TYPE fallback }) {
    return imp.first(k1: k1, k2: k2, where: where, fallback: fallback);
  }

  Future<VALUE_TYPE>  invalidCache(K1 k1, K2 k2, { SqlWhereObj where }) {
    return imp.invalidCache(k1: k1, k2: k2, where: where);
  }

  Future<bool>        contains(K1 k1, K2 k2, { SqlWhereObj where }) {
    return imp.contains(k1: k1, k2: k2, where: where);
  }

  Future<void>        forEach(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.forEach(processor, k1: k1, k2: k2, where: where);
  }

  Stream<VALUE_TYPE>  values({ K1 k1, K2 k2, SqlWhereObj where, VALUE_TYPE whereObj, }) {
    return imp.values(k1: k1, k2: k2, where: where, whereObj: whereObj);
  }

  Stream<VALUE_TYPE>  keys(String keyCol, { K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.keys(keyCol, k1: k1, k2: k2, where: where);
  }

  Future<void>                  clear({ K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.clear(k1: k1, k2: k2, where: where);
  }

  Future<int>                   size({ K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.size(k1: k1, k2: k2, where: where);
  }

}