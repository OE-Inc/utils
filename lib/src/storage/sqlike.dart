
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:utils/src/error.dart';
import 'package:utils/src/simple_interface.dart';
import 'package:utils/src/storage/engine/sqlite.dart';
import 'package:utils/src/unit.dart';

import '../log.dart';
import '../value_cached_map.dart';
import 'annotation/sql.dart';
import 'sql/table_info.dart';


const _TAG = "SqlLike";

class SqlTableFuncArg<VALUE_TYPE, K1, K2, K3> {
  K1 k1;
  K2 k2;
  K3 k3;
  SqlWhereObj where;
}

class SqlCacheKey<K1, K2, K3> {
  K1 k1;
  K2 k2;
  K3 k3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SqlCacheKey && k1 == other.k1 && k2 == other.k2 && k3 == other.k3;

  @override
  int get hashCode => k1.hashCode ^ (k2?.hashCode??0) ^ (k3?.hashCode??0);

  SqlCacheKey(this.k1, this.k2, this.k3);

  @override
  String toString() {
    return "$k1/$k2/$k3";
  }
}

abstract class SqlTableImp<VALUE_TYPE, K1, K2, K3> {
  SqlTableInfo<VALUE_TYPE>  tableInfo;
  String                    col1, col2, col3;

  int                       maxFullCacheSize = 128;

  String get  tableName => tableInfo.tableName;
  VALUE_TYPE get template => tableInfo.template;

  @protected
  ValueCacheMapAsync<SqlCacheKey<K1, K2, K3>, VALUE_TYPE>   cached;
  @protected
  List<VALUE_TYPE>            fullCache;

  SqlTableImp(this.tableInfo) {
    var ck = tableInfo.ck;
    col1 = ck[0];

    if (ck.length > 1)
      col2 = ck[1];

    if (ck.length > 2)
      col3 = ck[2];

    cached = ValueCacheMapAsync(10 * TimeUnit.MS_PER_MINUTE, (key, val, oldVal) async {
      var where = tableInfo.getWhere(template, true, false, false);

      if (key.k1 != null) where.compared(SqlWhereItem.OP_EQUAL, col1, key.k1);
      if (key.k2 != null) where.compared(SqlWhereItem.OP_EQUAL, col2, key.k2);
      if (key.k3 != null) where.compared(SqlWhereItem.OP_EQUAL, col3, key.k3);

      var ret = await getRaw(where);

      return ret.isEmpty ? null : ret[0];
    }, failInterval: 5*TimeUnit.MS_PER_MINUTE);
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

  bool isSingleKey(K1 k1, K2 k2, K3 k3, SqlWhereObj where) {
    var isSingle = (where == null || where.isEmpty(tableInfo.pkSet))
        &&  ((col1 == null) == (k1 == null))
        &&  ((col2 == null) == (k2 == null))
        &&  ((col3 == null) == (k3 == null))
    ;

    // Log.d(_TAG, 'isSingleKey = $isSingle, (pk: ${tableInfo.tableName}/${tableInfo.pkSet}), k1: $k1, k2: $k2, k3: $k3, where: $where, ');

    return isSingle;
  }

  bool isAllKey(K1 k1, K2 k2, K3 k3, SqlWhereObj where) {
    return (where == null || where.isEmpty(tableInfo.pkNoCkSet))
        && (k1 == null && k2 == null && k3 == null);
  }

  Future<List<VALUE_TYPE>> multiGetRaw(Iterable<SqlWhereObj> where) async {
    if (where == null || where.isEmpty) {
      // throw IllegalArgumentException('Should provide valid where array: $wheres');
      return [];
    }

    bool getAll = where.length == 1 && isAllKey(null, null, null, where.first);
    // Log.d(_TAG, "$tableName getAll: $getAll: ${where.first}");
    if (fullCache != null && getAll) {
      Log.d(_TAG, "use full cache: $tableName.");
      return fullCache;
    }

    var all = (await multiGetRawMap(where)).map((r) => tableInfo.fromSqlTransfer(r)).toList();

    if (getAll) {
      if (all.length <= maxFullCacheSize) {
        fullCache = all;
      } else
        Log.d(_TAG, "not use full cache: $tableName, out of maxFullCacheSize($maxFullCacheSize): ${all.length}.");
    }

    return all;
  }

  @protected
  Future<List<VALUE_TYPE>> getRaw(SqlWhereObj where) async {
    return multiGetRaw([where]);
  }

  @protected
  Future<List<Map<String, dynamic>>> getRawMap(SqlWhereObj where, { bool transferMap = true, }) {
    return multiGetRawMap([where], transferMap: transferMap);
  }

  @protected
  Future<List<Map<String, dynamic>>> multiGetRawMap(Iterable<SqlWhereObj> where, { bool transferMap = true, });

  Future<List<VALUE_TYPE>>  get({ K1 k1, K2 k2, K3 k3, VALUE_TYPE whereObj, SqlWhereObj where, }) async {
    if (isSingleKey(k1, k2, k3, where))
      return [await cached.getAsync(SqlCacheKey(k1, k2, k3))];

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

  Future<int>         multiRemove(Iterable<SqlWhereObj> values);

  Future<int>         multiSet(Iterable<VALUE_TYPE> values, { bool allowReplace = true, });
  Future<int>         set(VALUE_TYPE val, { bool allowReplace = true, });
  @Deprecated('use set/multiSet')
  Future<int>         update(VALUE_TYPE val);

  Future<int>         setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, });
  Future<int>         setFields(Map<String, dynamic> fields, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, });

  Future<bool>        containsKey({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<VALUE_TYPE>  first({ K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE fallback });

  Future<void>        invalidCache(K1 k1, K2 k2, K3 k3, SqlWhereObj where);

  Future<bool>        contains({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<void>        forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  // Future<void>        map(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });
  // Future<void>        filter(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<List<VALUE_TYPE>>      remove({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Stream<VALUE_TYPE>            values({ K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE whereObj, });
  Stream<KEY_TYPE>              keys<KEY_TYPE>(String keyCol, { K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  Future<int>                   clear({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });
  Future<int>                   size({ K1 k1, K2 k2, K3 k3, SqlWhereObj where });

  SqlWhereObj getWhere(VALUE_TYPE part, bool withPk, bool excludeCk, bool withNk, { SqlWhereObj where }) {
    return tableInfo.getWhere(part, withPk, excludeCk, withNk, where: where);
  }

  Future<bool> isTableExists();

  Future<void> createTable();

  Future<void> dropTable();

  Future<Map<String, SqlColumnDef>> readCols();

  invalidFullCache() {
    if (fullCache != null) Log.d(_TAG, "invalidFullCache: ${tableName}");
    fullCache = null;
  }

  clearCache() {
    Log.d(_TAG, "clearCache: ${tableName}");
    cached.clear();
    fullCache = null;
  }

}

abstract class SqlTable<VALUE_TYPE, K1, K2, K3, TABLE_INFO extends SqlTableInfo<VALUE_TYPE>> {
  SqlTableImp<VALUE_TYPE, K1, K2, K3>     imp;
  TABLE_INFO builder;

  SqlTable(this.builder) {
    imp = SqlTableImpSqlite<VALUE_TYPE, K1, K2, K3>(builder);
  }

  Future<List<VALUE_TYPE>>  multiGetWhere(Iterable<SqlWhereObj> wheres) {
    return imp.multiGetRaw(wheres);
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

  Future<List<VALUE_TYPE>>  multiGet(Iterable<K1> keys) {
    return multiGetWhere(keys.map((e) => imp.mergeWhere()..compared(SqlWhereItem.OP_EQUAL, imp.col1, e)));
  }

  Future<void>        set(VALUE_TYPE val) {
    return imp.set(val);
  }

  Future<void>        multiSet(Iterable<VALUE_TYPE> vals) {
    return imp.multiSet(vals);
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

  Future<void>  multiRemove(Iterable<K1> keys, { String col }) {
    return imp.multiRemove(keys.map((e) => imp.mergeWhere()..compared(SqlWhereItem.OP_EQUAL, col ?? imp.col1, e)));
  }

  Future<VALUE_TYPE>  remove(K1 k1, { SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, where: where);
    if (r.length > 1)
      throw IllegalArgumentException('Should use removeWhere for removing mutli data.');

    return r.isEmpty ? null : r[0];
  }

  Future<Iterable<VALUE_TYPE>>  removeWhere({ K1 k1, SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, where: where);
    return r;
  }

  Future<VALUE_TYPE>  first({ K1 k1, SqlWhereObj where, VALUE_TYPE fallback }) {
    return imp.first(k1: k1, where: where, fallback: fallback);
  }

  Future<VALUE_TYPE>  invalidCache(K1 k1, { SqlWhereObj where }) {
    return imp.invalidCache(k1, null, null, where);
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
  Stream<KEY_TYPE>    keys<KEY_TYPE>(String keyCol, { K1 k1, SqlWhereObj where }) {
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

  /// keys: [[k1, k2], [k1, k2], ..., ];
  Future<List<VALUE_TYPE>>  multiGet(Iterable<List> keys) {
    return multiGetWhere(keys.map((e) {
      var where = SqlWhereObj();

      if (e.isEmpty || (e[0] == null && e[1] == null)) {
        throw IllegalArgumentException("Should not multiGet with invalid k1,k2: $e");
      }

      if (e[0] != null)
        where.compared(SqlWhereItem.OP_EQUAL, imp.col1, e[0]);

      if (e[1] != null)
        where.compared(SqlWhereItem.OP_EQUAL, imp.col2, e[1]);

      return where;
    }));
  }

  Future<void>        set(VALUE_TYPE val) {
    return imp.set(val);
  }

  Future<void>        multiSet(Iterable<VALUE_TYPE> values) {
    return imp.multiSet(values);
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

  /// [ [k1, k2], ... ]
  Future<void>  multiRemove(Iterable<List<dynamic>> keys) {
    return imp.multiRemove(keys.map((e) {
      var where = imp.mergeWhere();

      e[0] ?? where.equal(imp.col1, e[0]);
      e[1] ?? where.equal(imp.col1, e[1]);

      return where;
    }));
  }

  Future<VALUE_TYPE>  remove(K1 k1, K2 k2, { SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, k2: k2, where: where);
    if (r.length > 1)
      Log.e(_TAG, 'Should use removeWhere for removing mutli data.\n${StackTrace.current}');

    return r.isEmpty ? null : r[0];
  }

  Future<Iterable<VALUE_TYPE>>  removeWhere({ K1 k1, K2 k2, SqlWhereObj where }) async {
    var r = await imp.remove(k1: k1, k2: k2, where: where);
    return r;
  }

  Future<VALUE_TYPE>  first({ K1 k1, K2 k2, SqlWhereObj where, VALUE_TYPE fallback }) {
    return imp.first(k1: k1, k2: k2, where: where, fallback: fallback);
  }

  Future<VALUE_TYPE>  invalidCache(K1 k1, K2 k2, { SqlWhereObj where }) {
    return imp.invalidCache(k1, k2, null, where);
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

  Stream<KEY_TYPE>    keys<KEY_TYPE>(String keyCol, { K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.keys(keyCol, k1: k1, k2: k2, where: where);
  }

  Future<void>                  clear({ K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.clear(k1: k1, k2: k2, where: where);
  }

  Future<int>                   size({ K1 k1, K2 k2, SqlWhereObj where }) {
    return imp.size(k1: k1, k2: k2, where: where);
  }

}