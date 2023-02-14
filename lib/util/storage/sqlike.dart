
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:utils/util/error.dart';
import 'package:utils/util/pair.dart';
import 'package:utils/util/running_env.dart';
import 'package:utils/util/simple_interface.dart';
import 'package:utils/util/storage/engine/sqlite.dart';
import 'package:utils/util/unit.dart';
import 'package:utils/util/utils.dart';

import '../log.dart';
import '../multi_completer.dart';
import '../value_cached_map.dart';
import 'annotation/sql.dart';
import 'sql/table_info.dart';


const _TAG = "SqlLike";

class SqlTableFuncArg<VALUE_TYPE, K1, K2, K3> {
  K1? k1;
  K2? k2;
  K3? k3;
  SqlWhereObj? where;
}

class SqlCacheKey<K1, K2, K3> {
  K1? k1;
  K2? k2;
  K3? k3;

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

abstract class SqlTableImp<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3> {
  static const CACHE_ALL_KEY = "*";

  SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL>  tableInfo;
  /// default null, for none-column.
  late String               col1;
  String?                   col2, col3;

  int                       maxFullCacheSize = 2*2048;

  String get  tableName => tableInfo.tableName;
  VALUE_TYPE_PARTIAL get template => tableInfo.template;

  @protected
  late ValueCacheMapAsync<SqlCacheKey<K1, K2, K3>, VALUE_TYPE?>   cached;

  @protected
  late  ValueCacheMap<String, List<VALUE_TYPE>?>                  batchCache;
  @protected
  List<VALUE_TYPE>? get                                           fullCache => batchCache.get(CACHE_ALL_KEY);

  @protected
  late ValueCacheMap<SqlCacheKey<K1, K2, K3>, MultiCompleter<VALUE_TYPE?>?>   pendingCached;

  SqlTableImp(this.tableInfo) {
    var ck = tableInfo.ck;
    col1 = ck[0];

    if (ck.length > 1)
      col2 = ck[1];

    if (ck.length > 2)
      col3 = ck[2];

    pendingCached = ValueCacheMap(3000, (key, old, utc) => null);

    cached = ValueCacheMapAsync(10 * TimeUnit.MS_PER_MINUTE, (key, oldVal, updateUtc) async {
      var pending = pendingCached.get(key);
      if (pending != null)
        return await pending.wait();

      pending = MultiCompleter();
      pendingCached.set(key, pending);

      var where = tableInfo.getWhere(template, true, false, false);

      if (key.k1 != null) where.compared(SqlWhereItem.OP_EQUAL, col1, key.k1);
      if (key.k2 != null) where.compared(SqlWhereItem.OP_EQUAL, col2!, key.k2);
      if (key.k3 != null) where.compared(SqlWhereItem.OP_EQUAL, col3!, key.k3);

      try {
        var ret = await getRaw(where);
        var val = ret.isEmpty ? null : ret[0];
        pending.complete(val, null);
        return val;
      } catch (e) {
        pending.complete(null, e);
        return null;
      } finally {
        pendingCached.invalidate(key);
      }
    }, failInterval: 5*TimeUnit.MS_PER_MINUTE);

    batchCache = ValueCacheMap(10 * TimeUnit.MS_PER_MINUTE, (key, old, utc) => null);
  }

  static String toPrintable(List args, { List? argNames, int? maxCount, dynamic toPrint(dynamic e)? }) {
    var count = args.length;
    if (count == 0)
      return '[0]';

    maxCount ??= 16;
    String append = '';
    if (args.length > maxCount) {
      args = args.sublist(0, maxCount);
      append = ' ...';
    }

    var list = toPrint != null
        ? args.map(toPrint).toList()
        : args
    ;

    if (argNames != null) {
      var maxLength = argNames.fold<int>(0, (pv, elem) => max(pv, (elem is String ? elem : '$elem').length));
      list = list.mapIndexed((item, index) => index >= argNames.length
          ? item
          : '${'${argNames[index]}'.alignTo(maxLength)} : [${args[index]?.runtimeType}] $item'
      ).toList();
    }

    return '[$count$append]\n-  ${list.join(',\n-  ')}';
  }

  SqlWhereObj mergeWhere({K1? k1, K2? k2, K3? k3, VALUE_TYPE_PARTIAL? whereObj, SqlWhereObj? where }) {
    if (whereObj != null) {
      where = tableInfo.simpleWhere(whereObj, where: where);
    }

    where = getWhere(template, true, false, false, where: where);

    if (k1 != null) where.compared(SqlWhereItem.OP_EQUAL, col1, k1);
    if (k2 != null) where.compared(SqlWhereItem.OP_EQUAL, col2!, k2);
    if (k3 != null) where.compared(SqlWhereItem.OP_EQUAL, col3!, k3);

    return where;
  }

  bool isSingleKey(K1? k1, K2? k2, K3? k3, SqlWhereObj? where) {
    var isSingle = (where == null || where.isEmpty(tableInfo.pkSet))
        &&  ((col1 == null) == (k1 == null))
        &&  ((col2 == null) == (k2 == null))
        &&  ((col3 == null) == (k3 == null))
    ;

    // Log.d(_TAG, () => 'isSingleKey = $isSingle, (pk: ${tableInfo.tableName}/${tableInfo.pkSet}), k1: $k1, k2: $k2, k3: $k3, where: $where, ');

    return isSingle;
  }

  bool isAllKey(K1? k1, K2? k2, K3? k3, SqlWhereObj? where) {
    return (where == null || where.isEmpty(tableInfo.pkNoCkSet))
        && (k1 == null && k2 == null && k3 == null);
  }

  Future<List<VALUE_TYPE>> multiGetRaw(Iterable<SqlWhereObj>? where) async {
    if (where == null || where.isEmpty) {
      // throw IllegalArgumentException('Should provide valid where array: $wheres');
      return [];
    }

    bool getAll = where.length == 1 && isAllKey(null, null, null, where.first);
    String cacheString = getAll ? CACHE_ALL_KEY : where.map((wo) => wo.cacheString).join(';');

    // NOTE: check invalid cache string.
    var isValid = !cacheString.contains('Instance of');
    if (RunningEnv.isDebug && !isValid) {
      throw UnsupportedError("$tableName multiGetRaw cacheString invalid: $cacheString.");
    }

    // Log.d(_TAG, () => "$tableName multiGetRaw cacheString: $cacheString.");

    // NOTE: not use invalid result.
    List<VALUE_TYPE>? result = !isValid ? null : batchCache.get(cacheString);
    if (result != null) {
      Log.d(_TAG, () => "$tableName multiGetRaw cached: $cacheString, result: ${toPrintable(result!)}.");
      return result;
    }

    var raw = await multiGetRawMap(where);
    result = [];

    var idx = 0;
    for (var r in raw) {
      if ((++idx % 10) == 0)
        await delay(1);

      result.add(tableInfo.fromSqlTransfer(r));
    }

    if (result.length <= maxFullCacheSize) {
      batchCache.set(cacheString, result);
    } else
      Log.d(_TAG, () => "not use batch cache: $tableName, out of maxFullCacheSize($maxFullCacheSize): ${result!.length}.");

    return result;
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

  Future<List<VALUE_TYPE>>  get({ K1? k1, K2? k2, K3? k3, VALUE_TYPE_PARTIAL? whereObj, SqlWhereObj? where, }) async {
    if (isSingleKey(k1, k2, k3, where))
      return [await cached.getAsync(SqlCacheKey(k1, k2, k3))];

    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where, whereObj: whereObj);
    return getRaw(where);
  }

  Future<FIELD_TYPE>        getField<FIELD_TYPE>(String field, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where, FIELD_TYPE? fallback, }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    where.columns = [field];

    var result = await getRawMap(where);
    if (result.length > 1)
      throw IllegalArgumentException('Should always getField() for a single/primaryKey item.');

    var item = result.isNotEmpty ? tableInfo.fromSqlTransferMap(result[0]) : null;
    return item != null ? (item[field]??fallback) : fallback;
  }

  Future<int>         multiRemove(Iterable<SqlWhereObj> values);

  Future<int>         multiSet(Iterable<VALUE_TYPE> values, { bool allowReplace = true, });
  Future<int>         set(VALUE_TYPE val, { bool allowReplace = true, });
  @Deprecated('use set/multiSet')
  Future<int>         update(VALUE_TYPE val);

  Future<int>         setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where, });
  Future<int>         setFields(Map<String, dynamic> fields, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where, });

  Future<bool>        containsKey({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  Future<VALUE_TYPE?> first({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE? fallback });

  Future<void>        invalidCache(K1? k1, K2? k2, K3? k3, SqlWhereObj? where);

  Future<bool>        contains({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  Future<void>        forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  // Future<void>        map(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj? where });
  // Future<void>        filter(Callable1<VALUE_TYPE, bool> processor, { K1 k1, K2 k2, K3 k3, SqlWhereObj? where });

  Future<List<VALUE_TYPE>>      remove({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  Stream<VALUE_TYPE>            values({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, });
  // Stream<VALUE_TYPE_PARTIAL>    partValues({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, });
  Stream<KEY_TYPE>              keys<KEY_TYPE>(String keyCol, { bool? withPkKeys, K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  Future<int>                   clear({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where });
  Future<int>                   size({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where });

  SqlWhereObj getWhere(VALUE_TYPE_PARTIAL part, bool withPk, bool excludeCk, bool withNk, { SqlWhereObj? where }) {
    return tableInfo.getWhere(part, withPk, excludeCk, withNk, where: where);
  }

  Future<bool> isTableExists();

  Future<void> createTable({ bool debugCheckInit = false, });

  Future<void> dropTable();

  Future<Map<String, SqlColumnDef>> readCols();

  invalidBatchCache() {
    if (batchCache.length > 0) Log.d(_TAG, () => "invalidBatchCache: ${tableName}");
    batchCache.clear();
  }

  clearCache() {
    Log.d(_TAG, () => "clearCache: ${tableName}");
    cached.clear();
    invalidBatchCache();
  }

}

abstract class SqlTable<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3, TABLE_INFO extends SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL>> {
  late SqlTableImp<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3>  imp;
  TABLE_INFO builder;

  SqlTable(this.builder) {
    imp = SqlTableImpSqlite<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3>(builder);
  }

  Future<void>        set(VALUE_TYPE val) {
    return imp.set(val);
  }

  Future<void>        multiSet(Iterable<VALUE_TYPE> values) {
    return imp.multiSet(values);
  }

  Future<List<VALUE_TYPE>>  multiGetWhere(Iterable<SqlWhereObj> wheres) {
    return imp.multiGetRaw(wheres);
  }

  Future<void> createTable({ bool debugCheckInit = false, }) { return imp.createTable(debugCheckInit: debugCheckInit); }

  Future<bool> isTableExists() { return imp.isTableExists(); }

  Future<void> dropTable() { return imp.dropTable(); }

  Future<Map<String, SqlColumnDef>> readCols() { return imp.readCols(); }
}

class SqlTable1N<K1, VALUE_TYPE, VALUE_TYPE_PARTIAL, TABLE_INFO extends SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL>> extends SqlTable<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, void, void, TABLE_INFO> {
  SqlTable1N(TABLE_INFO builder) : super(builder);

  Future<VALUE_TYPE?> get(K1? k1, { SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, VALUE_TYPE? fallback, }) async {
    var r = await imp.get(k1: k1, where: where, whereObj: whereObj);
    if (r.length > 1)
      throw SqlException(-1, "Something is error in table defines, should never have duplicate objects.");

    return (r.isEmpty ? null : r[0]) ?? fallback;
  }

  Future<List<VALUE_TYPE>>  multiGet(Iterable<K1> keys) {
    return multiGetWhere(keys.map((e) => imp.mergeWhere()..compared(SqlWhereItem.OP_EQUAL, imp.col1, e)));
  }

  Future<FIELD_TYPE>  getField<FIELD_TYPE>(K1 k1, String field, { SqlWhereObj? where, FIELD_TYPE? fallback, }) {
    return imp.getField(field, k1: k1, where: where, fallback: fallback);
  }

  Future<int>         setField<FIELD_TYPE>(K1 k1, String field, FIELD_TYPE fieldVal, { SqlWhereObj? where, }) {
    return imp.setField(field, fieldVal, k1: k1, where: where);
  }

  Future<int>         setFields<FIELD_TYPE>(K1 k1, Map<String, dynamic> fields, { SqlWhereObj? where, }) {
    return imp.setFields(fields, k1: k1, where: where);
  }

  Future<bool>        containsKey( K1 k1, { SqlWhereObj? where }) {
    return imp.containsKey(k1: k1, where: where);
  }

  Future<void>  multiRemove(Iterable<K1> keys, { String? col }) {
    return imp.multiRemove(keys.map((e) => imp.mergeWhere()..compared(SqlWhereItem.OP_EQUAL, col ?? imp.col1, e)));
  }

  Future<VALUE_TYPE?> remove(K1 k1, { SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, where: where);
    if (r.length > 1)
      throw IllegalArgumentException('Should use removeWhere for removing multi data.');

    return r.isEmpty ? null : r[0];
  }

  Future<Iterable<VALUE_TYPE>>  removeWhere({ K1? k1, SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, where: where);
    return r;
  }

  Future<VALUE_TYPE?> first({ K1? k1, SqlWhereObj? where, VALUE_TYPE? fallback }) {
    return imp.first(k1: k1, where: where, fallback: fallback);
  }

  Future<void>        invalidCache(K1 k1, { SqlWhereObj? where }) {
    return imp.invalidCache(k1, null, null, where);
  }

  Future<bool>        contains(K1 k1, { SqlWhereObj? where }) {
    return imp.contains(k1: k1, where: where);
  }

  Future<void>        forEach(Callable1<VALUE_TYPE, bool> processor, { K1? k1, SqlWhereObj? where }) {
    return imp.forEach(processor, k1: k1, where: where);
  }

  /*
  Stream<VALUE_TYPE_PARTIAL>  partValues({ K1? k1, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, }) {
    return imp.partValues(k1: k1, where: where, whereObj: whereObj);
  }
   */

  Stream<VALUE_TYPE>  values({ K1? k1, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, }) {
    return imp.values(k1: k1, where: where, whereObj: whereObj);
  }

  Stream<KEY_TYPE>    keys<KEY_TYPE>(String keyCol, { K1? k1, SqlWhereObj? where }) {
    return imp.keys(keyCol, k1: k1, where: where);
  }

  Future<void>                  clear({ K1? k1, SqlWhereObj? where }) {
    return imp.clear(k1: k1, where: where);
  }

  Future<int>                   size({ K1? k1, SqlWhereObj? where }) {
    return imp.size(k1: k1, where: where);
  }
}

class SqlTableNN<K1, K2, VALUE_TYPE, VALUE_TYPE_PARTIAL, TABLE_INFO extends SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL>> extends SqlTable<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, void, TABLE_INFO> {
  SqlTableNN(TABLE_INFO builder) : super(builder);

  Future<VALUE_TYPE?> get(K1? k1, K2? k2, { SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, VALUE_TYPE? fallback, }) async {
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

      if (e[0] != null) where.equal(imp.col1, e[0]);
      if (e[1] != null) where.equal(imp.col2!, e[1]);

      return where;
    }));
  }

  Future<FIELD_TYPE>  getField<FIELD_TYPE>(K1 k1, K2 k2, String field, { SqlWhereObj? where, FIELD_TYPE? fallback, }) {
    return imp.getField(field, k1: k1, k2: k2, where: where, fallback: fallback);
  }

  Future<int>         setField<FIELD_TYPE>(K1? k1, K2? k2, String field, FIELD_TYPE fieldVal, { SqlWhereObj? where, }) {
    return imp.setField(field, fieldVal, k1: k1, k2: k2, where: where);
  }

  Future<int>         setFields<FIELD_TYPE>(K1? k1, K2? k2, Map<String, dynamic> fields, { SqlWhereObj? where, }) {
    return imp.setFields(fields, k1: k1, k2: k2, where: where);
  }

  Future<bool>        containsKey( K1 k1, K2 k2, { SqlWhereObj? where }) {
    return imp.containsKey(k1: k1, k2: k2, where: where);
  }

  /// [ [k1, k2], ... ]
  Future<void>  multiRemove(Iterable<Pair<K1?, K2?>> keys) {
    return imp.multiRemove(keys.map((e) {
      var where = imp.mergeWhere();

      if (e.f != null) where.equal(imp.col1, e.f);
      if (e.s != null) where.equal(imp.col2!, e.s);

      return where;
    }));
  }

  Future<VALUE_TYPE?> remove(K1? k1, K2? k2, { SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, k2: k2, where: where);
    if (r.length > 1)
      Log.e(_TAG, () => 'Should use removeWhere for removing multi data.\n${StackTrace.current}');

    return r.isEmpty ? null : r[0];
  }

  Future<Iterable<VALUE_TYPE>>  removeWhere({ K1? k1, K2? k2, SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, k2: k2, where: where);
    return r;
  }

  Future<VALUE_TYPE?> first({ K1? k1, K2? k2, SqlWhereObj? where, VALUE_TYPE? fallback }) {
    return imp.first(k1: k1, k2: k2, where: where, fallback: fallback);
  }

  Future<void>        invalidCache(K1? k1, K2? k2, { SqlWhereObj? where }) {
    return imp.invalidCache(k1, k2, null, where);
  }

  Future<bool>        contains(K1? k1, K2? k2, { SqlWhereObj? where }) {
    return imp.contains(k1: k1, k2: k2, where: where);
  }

  Future<void>        forEach(Callable1<VALUE_TYPE, bool> processor, { K1? k1, K2? k2, SqlWhereObj? where }) {
    return imp.forEach(processor, k1: k1, k2: k2, where: where);
  }

  Stream<VALUE_TYPE>  values({ K1? k1, K2? k2, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, }) {
    return imp.values(k1: k1, k2: k2, where: where, whereObj: whereObj);
  }

  Stream<KEY_TYPE>    keys<KEY_TYPE>(String keyCol, { bool? withPkKeys, K1? k1, K2? k2, SqlWhereObj? where }) {
    return imp.keys(keyCol, k1: k1, k2: k2, where: where, withPkKeys: withPkKeys);
  }

  Future<void>                  clear({ K1? k1, K2? k2, SqlWhereObj? where }) {
    return imp.clear(k1: k1, k2: k2, where: where);
  }

  Future<int>                   size({ K1? k1, K2? k2, SqlWhereObj? where }) {
    return imp.size(k1: k1, k2: k2, where: where);
  }

}



class SqlTableNNN<K1, K2, K3, VALUE_TYPE, VALUE_TYPE_PARTIAL, TABLE_INFO extends SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL>> extends SqlTable<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3, TABLE_INFO> {
  SqlTableNNN(TABLE_INFO builder) : super(builder);

  Future<VALUE_TYPE?>  get(K1 k1, K2 k2, K3 k3, { SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, VALUE_TYPE? fallback, }) async {
    var r = await imp.get(k1: k1, k2: k2, where: where, whereObj: whereObj);
    if (r.length > 1)
      throw SqlException(-1, "Something is error in table defines, should never have duplicate objects.");

    return (r.isEmpty ? null : r[0]) ?? fallback;
  }

  /// keys: [[k1, k2, k3], [k1, k2, k3], ..., ];
  Future<List<VALUE_TYPE>>  multiGet(Iterable<List> keys) {
    return multiGetWhere(keys.map((e) {
      var where = SqlWhereObj();

      if (e.isEmpty || (e[0] == null && e[1] == null && e[2] == null)) {
        throw IllegalArgumentException("Should not multiGet with invalid k1,k2,k3: $e");
      }

      if (e[0] != null) where.equal(imp.col1, e[0]);
      if (e[1] != null) where.equal(imp.col2!, e[1]);
      if (e[2] != null) where.equal(imp.col3!, e[2]);

      return where;
    }));
  }

  Future<FIELD_TYPE>  getField<FIELD_TYPE>(K1 k1, K2 k2, K3 k3, String field, { SqlWhereObj? where, FIELD_TYPE? fallback, }) {
    return imp.getField(field, k1: k1, k2: k2, k3: k3, where: where, fallback: fallback);
  }

  Future<int>         setField<FIELD_TYPE>(K1 k1, K2 k2, K3 k3, String field, FIELD_TYPE fieldVal, { SqlWhereObj? where, }) {
    return imp.setField(field, fieldVal, k1: k1, k2: k2, k3: k3, where: where);
  }

  Future<int>         setFields<FIELD_TYPE>(K1 k1, K2 k2, K3 k3, Map<String, dynamic> fields, { SqlWhereObj? where, }) {
    return imp.setFields(fields, k1: k1, k2: k2, k3: k3, where: where);
  }

  Future<bool>        containsKey( K1 k1, K2 k2, K3 k3, { SqlWhereObj? where }) {
    return imp.containsKey(k1: k1, k2: k2, k3: k3, where: where);
  }

  /// [ [k1, k2], ... ]
  Future<void>  multiRemove(Iterable<Triple<K1, K2, K3>> keys) {
    return imp.multiRemove(keys.map((e) {
      var where = imp.mergeWhere();

      if (e.v1 != null) where.equal(imp.col1, e.v1);
      if (e.v2 != null) where.equal(imp.col2!, e.v2);
      if (e.v3 != null) where.equal(imp.col3!, e.v3);

      return where;
    }));
  }

  Future<VALUE_TYPE?>  remove(K1 k1, K2 k2, K3 k3, { SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, k2: k2, k3: k3, where: where);
    if (r.length > 1)
      Log.e(_TAG, () => 'Should use removeWhere for removing multi data.\n${StackTrace.current}');

    return r.isEmpty ? null : r[0];
  }

  Future<Iterable<VALUE_TYPE>>  removeWhere({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) async {
    var r = await imp.remove(k1: k1, k2: k2, k3: k3, where: where);
    return r;
  }

  Future<VALUE_TYPE?>  first({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE? fallback }) {
    return imp.first(k1: k1, k2: k2, k3: k3, where: where, fallback: fallback);
  }

  Future<void>        invalidCache(K1 k1, K2 k2, K3 k3, { SqlWhereObj? where }) {
    return imp.invalidCache(k1, k2, null, where);
  }

  Future<bool>        contains(K1 k1, K2 k2, K3 k3, { SqlWhereObj? where }) {
    return imp.contains(k1: k1, k2: k2, k3: k3, where: where);
  }

  Future<void>        forEach(Callable1<VALUE_TYPE, bool> processor, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) {
    return imp.forEach(processor, k1: k1, k2: k2, k3: k3, where: where);
  }

  Stream<VALUE_TYPE>  values({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, }) {
    return imp.values(k1: k1, k2: k2, k3: k3, where: where, whereObj: whereObj);
  }

  Stream<KEY_TYPE>    keys<KEY_TYPE>(String keyCol, { bool? withPkKeys, K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) {
    return imp.keys(keyCol, k1: k1, k2: k2, k3: k3, where: where, withPkKeys: withPkKeys);
  }

  Future<void>                  clear({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) {
    return imp.clear(k1: k1, k2: k2, k3: k3, where: where);
  }

  Future<int>                   size({ K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) {
    return imp.size(k1: k1, k2: k2, k3: k3, where: where);
  }

}