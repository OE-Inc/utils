

import 'dart:async';

import 'package:utils/util/running_env.dart';
import 'package:utils/util/simple_interface.dart';
import 'package:utils/util/storage/annotation/sql.dart';
import 'package:utils/util/storage/index.dart';
import 'package:utils/util/storage/sql/table_info.dart';

import '../../log.dart';
import '../sqlike.dart';
import 'database.dart';

const String _TAG = 'SqlTableImpSqlite';

final bool updateDryRun = false && !RunningEnv.isRelease;

class DatabaseProvider {
  SqliteDatabase?  _db;

  Map<String, Callable1<bool, Future<void>>> tables = { };

  List<Callable2<SqliteDatabase, int, void>> onCreates = [];
  List<Callable3<SqliteDatabase, int, int, void>> onUpgrades = [];

  DatabaseProvider();

  bool isInitialized() => _db != null;

  SqliteDatabase getDb() {
    if (_db == null)
      throw RuntimeException("Should always call databaseProvider.initialize() when startup.");

    return _db!;
  }

  Future<void> initTables({ bool debugCheckInit = false, }) async {
    Log.i(_TAG, () => "creating tables: ${tables.keys}");

    for (var table in tables.keys) {
      Log.i(_TAG, () => "creating table: $table");
      await tables[table]!(debugCheckInit);
    }
  }


  Future<SqliteDatabase> initialize([int? latestVersion]) async {
    if (_db != null)
      return _db!;

    var version = latestVersion ?? 20200714;

    Log.i(_TAG, () => "initialize database start, version: $version");
    _db = SqliteDatabase.getDb('main.db');

    bool initialized = false;
    _db = await _db!.initialize(version,
      onCreate: (db, version) async {
        _db = db;

        Log.i(_TAG, () => "onCreate database $version");

        await initTables();

        for (var oc in onCreates)
          oc(db, version);

        initialized = true;
      },
      onUpgrade: (db, oldVer, newVer) async {
        _db = db;

        Log.i(_TAG, () => "onUpgrade database: $oldVer => $newVer");

        await initTables();

        for (var ou in onUpgrades)
          ou(db, oldVer, newVer);

        if (updateDryRun)
          throw RuntimeException('dryrun update sql.');

        initialized = true;
      },
    )
        .catchError((e, stacktrace) {
      Log.w(_TAG, () => 'initDb error: ', e, stacktrace);
      throw e;
    });

    if (!initialized && RunningEnv.isDebug) {
      await initTables(debugCheckInit: true);
    }

    Log.i(_TAG, () => "initialize database complete.");

    return _db!;
  }
}

final DatabaseProvider databaseProvider = DatabaseProvider();

class SqlTableImpSqlite<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3> extends SqlTableImp<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3> {
  bool debug = Log.enable || false;
  static int sequence = 0;

  SqliteDatabase get db => dbProvider.getDb();
  late DatabaseProvider dbProvider;

  SqlTableImpSqlite(SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> tableInfo, { DatabaseProvider? provider }) : super(tableInfo) {
    dbProvider = provider ?? databaseProvider;

    if (dbProvider.isInitialized() && !dbProvider.tables.containsKey(tableName)) {
      Log.e(_TAG, () => "database already initialized before table created, table may not created/updated.");
    }

    dbProvider.tables[tableName] = (debugCheckInit) => createTable(debugCheckInit: debugCheckInit);
  }

  static Future<void> updateTableIndex<VALUE_TYPE, VALUE_TYPE_PARTIAL>(SqliteDatabase db, String table, SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> tableInfo) async {
    /*
    var indexList = await db.rawQuery("PRAGMA TABLE_LIST('$table')");

    for (var index in indexList) {
      var indexList = await db.rawQuery("PRAGMA TABLE_LIST('$table')");
      var changed = false;

      if (!changed)
        return;

      await dropIndex();
      await createIndex();
    } */

    if (tableInfo.hasIndexes)
      Log.w(_TAG, () => "not support updateTableIndex now.");
  }

  static Future<void> updateTable<VALUE_TYPE, VALUE_TYPE_PARTIAL>(SqliteDatabase db, String table, SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> tableInfo, { bool debugCheckInit = false, }) async {
    Map<String, SqlColumnDef> columns = tableInfo.columns;

    var existed = <String, String> { };

    // defines see readCols().
    /*
    result format: {
      cid: 1...100,       // column index
      name: 'col name',   // column name
      type: 'TEXT',       // column type, eg: BLOB
      pk: 0/1...N,        // PrimaryKey, 0 for not, 1...N for pk index.
      notnull: 0/1,       // Has a NOT NULL constraint
      dflt_value: "123",  // default value of column.
    } */
    var result = await db.rawQuery("PRAGMA TABLE_INFO('$table')");
    Log.d(_TAG, () => "table($table) struct result: $result");

    if (result.length == 0)
      return;

    for (var col in result) {
      existed[col["name"] as String] = col["type"] as String;
    }

    bool addOrRenamed = false;
    Map<String, String> typeChangedCols = { };
    Map<String, String> renameCols = { };

    for (var col in columns.keys) {
      var c = columns[col]!;
      var existedType = existed[col];

      if (existedType != null) {
        if (existedType.toLowerCase() != c.type!.toLowerCase()) {
          typeChangedCols[col] = '$existedType(existed) => ${c.type}(new)';
          Log.i(_TAG, () => "table($table) column($col) type changed: ${typeChangedCols[col]}.");
        }

        continue;
      }

      addOrRenamed = true;
      var oldName = c.oldName;
      String sql;

      var rename = oldName != null && existed[oldName] != null;
      if (rename) {
        sql = "ALTER TABLE `$table` RENAME COLUMN `$oldName` TO `$col`";
      } else {
        var defaultValue = c.defaultValue ?? c.typeDefaultValue;
        if (defaultValue == null && !c.nullable)
          throw IllegalArgumentException("Cannot add a column with 'NOT NULL' but no 'DEFAULT VALUE'. table: $table, col: $col.");

        sql = "ALTER TABLE `$table` ADD `$col` ${c.type} DEFAULT '${defaultValue}'";
      }

      Log.v(_TAG, () => 'final SQL: $sql');

      if (debugCheckInit) {
        throw SqliteDatabaseException('rebuild error', 'should update db version, column changed: $table.');
      }

      try {
        if (updateDryRun && rename) renameCols[col] = oldName!;

        if (!updateDryRun) await db.execute(sql);
      } on SqliteDatabaseException catch (e) {
        if (rename && e.isSyntaxError() && e.toString().contains('near "COLUMN"')) {
          Log.w(_TAG, () => 'RENAME COLUMN ($oldName -> $col) failed, will move table($table) later.');
          renameCols[col] = oldName!;
        } else
          rethrow;
      }
    }

    if (addOrRenamed) {
      result = await db.rawQuery("PRAGMA TABLE_INFO('$table')");
      Log.d(_TAG, () => "table($table) struct result after addOrRenamed: $result");

      existed.clear();
      for (var col in result) {
        existed[col["name"] as String] = col["type"] as String;
      }
    }

    List<dynamic> oldPks = result
        .where((e) => e['pk'] as num > 0)
        .toList()
      ..sort((l, r) => ((l['pk'] as num) - (r['pk'] as num)).toInt());

    oldPks = oldPks.map((e) => e['name']).toList();
    var newPks = tableInfo.pk;

    var pkChanged = oldPks.join(',').toLowerCase() != newPks.join(',').toLowerCase();
    var deleteCols = existed.keys.where((e) => !tableInfo.columns.containsKey(e)).toList();

    if (pkChanged || deleteCols.isNotEmpty || renameCols.isNotEmpty || typeChangedCols.isNotEmpty) {
      Log.i(_TAG, () => '''\n
      ******************************************************************
      *
      *  TABLE: $table
      *
      *  struct changed, move and update table now:
      * 
      *  PRIMARY KEYS:  ${pkChanged ? '($oldPks => $newPks)' : '--'}
      *  DELETE COLS:   ${deleteCols.isNotEmpty ? deleteCols : '--'}
      *  RENAME COLS:   ${renameCols.isNotEmpty ? renameCols : '--'}
      *  CHANGE COLS:   ${typeChangedCols.isNotEmpty ? typeChangedCols : '--'}
      *
      ******************************************************************''');

      if (debugCheckInit) {
        throw SqliteDatabaseException('rebuild error', 'should update db version, table changed: $table.');
      }

      await updateMoveTable(db, table, tableInfo, deleteCols, renameCols, typeChangedCols);
    }
  }

  /// renameCols: { new: old, }
  static Future<void> updateMoveTable<VALUE_TYPE, VALUE_TYPE_PARTIAL>(SqliteDatabase db, String table, SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> tableInfo, List<String> deleteCols, Map<String, String> renameCols, Map<String, String> changedCols) async {
    bool noColChanges = deleteCols.isEmpty && renameCols.isEmpty && changedCols.isEmpty;
    var newCols = !noColChanges ? tableInfo.columns.keys : null;
    var oldCols = !noColChanges ? newCols!.map((e) => renameCols[e] ?? e) : null;

    var sql = '''
    /* Start moving table */
    
    DROP TABLE IF EXISTS `moving_$table`;
    CREATE TABLE `moving_$table` (${tableInfo.tableDefine()});

    ${noColChanges
      ? "INSERT OR REPLACE INTO `moving_$table` SELECT * FROM `$table`"
      : "INSERT OR REPLACE INTO `moving_$table` (${newCols!.join(',')}) SELECT ${oldCols!.join(',')} FROM `$table`"
    };

    DROP TABLE `$table`;
    ALTER TABLE `moving_$table` RENAME TO `$table`;
    
    /* End moving table */
    ''';

    bool justExecute = RunningEnv.isWeb;
    if (justExecute) {
      sql = '''
      PRAGMA foreign_keys=off;
  
      BEGIN TRANSACTION;
      
      $sql
      
      COMMIT TRANSACTION;
      
      PRAGMA foreign_keys=on;
      ''';

      Log.v(_TAG, () => 'final SQL: $sql');
      if (!updateDryRun) await db.execute(sql);
    } else {
      await db.transaction((txn) async {
        Log.v(_TAG, () => 'final SQL: $sql');

        if (!updateDryRun) {
          var ss = sql.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

          for (var s in ss) {
            s = s.trim();
            // skip comments.
            if (s.startsWith('/*') || s.startsWith('-- ')) continue;

            await txn.execute(s);
          }
        }
      });
    }
  }

  @override
  Future<int> clear({K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    int seq = sequence++;
    var sql = 'DELETE FROM `$tableName` ${w.v1}';
    if (debug) Log.v(_TAG, () => '[$seq] clear table: $sql.');

    var result = await db.rawDelete(sql, w.v2);
    invalidCache(k1, k2, k3, where);

    if (debug) Log.v(_TAG, () => '[$seq] clear table result: $result.');

    return result;
  }

  @override
  Future<bool> contains({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) async {
    return (await size(k1: k1, k2: k2, k3: k3, where: where)) > 0;
  }

  @override
  Future<bool> containsKey({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) async {
    return (await size(k1: k1, k2: k2, k3: k3, where: where)) > 0;
  }

  String toPrintableArgs(List args, List argNames) {
    return SqlTableImp.toPrintable(args, argNames: argNames, toPrint: (a) => a is Uint8List ? a.hexString() : a);
  }

  String toPrintableResults(List<Map> args) {
    return SqlTableImp.toPrintable(args, toPrint: (m) {
      Map<String, String> copied = {};

      for (var k in m.keys) {
        var v = m[k];

        copied[k] = '[${v.runtimeType}]${v is Uint8List ? v.hex : v}';
      }

      return copied;
    });
  }

  @override
  Future<VALUE_TYPE?> first({K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE? fallback}) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    where.limit = 1;

    var result = await getRaw(where);

    if (debug) Log.d(_TAG, () => 'first() result: $result.');

    return result.isNotEmpty ? (result[0] ?? fallback) : fallback;
  }

  @override
  Future<List<Map<String, dynamic>>> multiGetRawMap(Iterable<SqlWhereObj> wheres, { bool transferMap = true, }) async {
    if (wheres.isEmpty) {
      // throw IllegalArgumentException('Should provide valid where array: $wheres');
      return [];
    }

    List<String> sqlAll = [];
    List<Object> args = [];
    List argNames = [];

    for (var where in wheres) {
      var w = where.finalWhere(tableInfo);

      var distinct = where.distinct != null ? 'DISTINCT ' : '';
      if (where.distinct != null) {
        if (where.columns?.contains(where.distinct) == true)
          where.columns!.remove(where.distinct);

        where.columns ??= [];
        where.columns!.insert(0, where.distinct!);
      }

      var sel = ((where.columns?.isEmpty ?? true) ? '*' : where.columns!.map((c) => '`$c`').join(','));

      var sql = 'SELECT $distinct$sel FROM `$tableName` ${w.v1}';
      sqlAll.add(sql);
      args.addAll(w.v2);
      argNames.addAll(w.v3);
    }

    var sql = sqlAll.length == 1 ? sqlAll[0] : sqlAll.join('\n UNION\n');

    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(args, argNames)}');

    var result = await db.rawQuery(sql, args);

    if (debug) Log.d(_TAG, () => '[$seq] getRaw() SQL: $sql, result: ${toPrintableResults(result)}.');

    if (result.isEmpty)
      return [];

    if (!transferMap)
      return result;

    List<Map<String, dynamic>> mapped = [];

    int idx = 0;
    for (var r in result) {
      if ((++idx % 10) == 0)
        await delay(1);

      mapped.add(tableInfo.fromSqlTransferMap(r));
    }

    return mapped;
  }

  @override
  Future<void> invalidCache(K1? k1, K2? k2, K3? k3, SqlWhereObj? where) async {
    if (isSingleKey(k1, k2, k3, where)) {
      // if (debug) Log.d(_TAG, () => 'invalid single key: k1: $k1, k2: $k2, k3: $k3');
      cached.invalidate(SqlCacheKey(k1, k2, k3));
    } else {
      // if (debug) Log.d(_TAG, () => 'invalid all key: k1: $k1, k2: $k2, k3: $k3, where: $where.');
      cached.clear();
    }

    invalidBatchCache();
  }

  @override
  Future<int> multiRemove(Iterable<SqlWhereObj> values) async {
    int seq = sequence++;

    if (debug) Log.v(_TAG, () => '[$seq] start batch transaction.');
    var batch = db.batch();

    int subSeq = 1;

    var len = 0;
    for (var where in values) {
      var w = where.finalWhere(tableInfo);
      var sql = 'DELETE FROM `$tableName` ${w.v1}';
      if (debug) Log.v(_TAG, () => '[$seq.${subSeq++}] final batch SQL: $sql，args: ${toPrintableArgs(w.v2, w.v3)}');

      batch.rawDelete(sql, w.v2);
      ++len;
    }

    await batch.commit();
    if (debug) Log.v(_TAG, () => '[$seq] committed batch transaction.');

    clearCache();
    return len;
  }

  @override
  Future<List<VALUE_TYPE>> remove({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var existed = await get(k1: k1, k2: k2, k3: k3, where: where);

    var sql = 'DELETE FROM `$tableName` ${w.v1}';
    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(w.v2, w.v3)}');

    await db.execute(sql, w.v2);

    invalidCache(k1, k2, k3, where);
    if (debug) Log.v(_TAG, () => '[$seq] remove() complete.');

    return existed;
  }

  @override
  Future<int>         multiSet(Iterable<VALUE_TYPE> values, { bool allowReplace = true, }) async {
    var batch = db.batch();

    var len = 0;
    for (var val in values) {
      var raw = rawInsert(val, allowReplace: allowReplace, clearCache: false);

      String sql = raw[0];
      List<Object> args = raw[1];
      List<String> argNames = raw[2];

      int seq = sequence++;
      if (debug) Log.v(_TAG, () => '[$seq] final batch SQL: $sql，args: ${toPrintableArgs(args, argNames)}');

      batch.rawInsert(sql, args);
      ++len;
    }

    await batch.commit();

    clearCache();
    return len;
  }

  @override
  Future<int> set(VALUE_TYPE val, { bool allowReplace = true, }) async {
    var raw = rawInsert(val, allowReplace: allowReplace);
    
    String sql = raw[0];
    List<Object> args = (raw[1] as List).cast<Object>();
    List<dynamic> argNames = raw[2];

    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql，args: ${toPrintableArgs(args, argNames)}');

    var result = await db.rawInsert(sql, args);

    var clearCacheRun = raw[3];
    if (clearCacheRun != null) clearCacheRun();

    if (debug) Log.d(_TAG, () => '[$seq] set() result: $result.');

    return result;
  }

  /// returns [
  ///   sql,
  ///   [...args],
  ///   [...argNames],
  ///   clearCacheRunner
  /// ]
  List<dynamic> rawInsert(VALUE_TYPE val, { bool allowReplace = true, bool clearCache = true, }) {
    var rawMap = tableInfo.toSql(val);
    var k1 = rawMap[col1], k2 = rawMap[col2], k3 = rawMap[col3];

    var saved = tableInfo.toSqlTransferMap(rawMap);
    var keys = saved.keys.toList();

    var ins = (allowReplace ? "INSERT OR REPLACE INTO" : "INSERT INTO");

    var sql = '$ins `$tableName` (${keys.map((f) => '`$f`').join(',')}) VALUES (${keys.map((f) => '?').join(',')})';

    var argNames = <String>[];
    var args = keys.map((e) {
      var val = saved[e];
      argNames.add(e);
      if (val == null && debug) Log.w(_TAG, () => 'insert/set null field: $e of ${tableInfo.tableName}.');

      return val;
    }).toList();

    return [sql, args, argNames, clearCache ? () => invalidCache(k1, k2, k3, null) : null];
  }

  @override
  Future<int> update(VALUE_TYPE val) async {
    var saved = tableInfo.toSqlTransfer(val, excludePk: true);
    var keys = saved.keys.toList();
    var where = getWhere(tableInfo.toPartial(val), true, false, false);
    var w = where.finalWhere(tableInfo);

    var args = <Object> [...keys.map((k) => saved[k]), ...w.v2];

    var sql = 'UPDATE `$tableName` SET ${keys.map((c) => '`$c`=?').join(',')} ${w.v1}';
    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(args, [...keys, ...w.v3])}');

    var result = await db.rawUpdate(sql, args);

    if (debug) Log.d(_TAG, () => '[$seq] update() result: $result.');

    return result;
  }

  @override
  Future<int> setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, {K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var sql = 'UPDATE `$tableName` SET `$field`=? ${w.v1}';
    var args = <Object> [tableInfo.columns[field]!.toSql(fieldVal), ...w.v2];

    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(args, [field, ...w.v3])}');

    var result = await db.rawUpdate(sql, args);
    invalidCache(k1, k2, k3, where);

    if (debug) Log.d(_TAG, () => '[$seq] update() result: $result.');

    return result;
  }

  @override
  Future<int> setFields(Map<String, dynamic> fields, { K1? k1, K2? k2, K3? k3, SqlWhereObj? where, }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var args = <Object>[];
    var argNames = [];
    var sets = fields.keys.map((f) {
      var v = fields[f];
      if (v == null)
        return null;
      
      args.add(tableInfo.columns[f]!.toSql(v));
      argNames.add(f);
      return '`$f`=?';
    }).where((s) => s != null).join(',');

    var sql = 'UPDATE `$tableName` SET $sets ${w.v1}';
    args = [...args, ...w.v2];
    argNames = [...argNames, ...w.v3];

    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(args, argNames)}');

    var result = await db.rawUpdate(sql, args);
    invalidCache(k1, k2, k3, where);

    if (debug) Log.d(_TAG, () => '[$seq] update() result: $result.');

    return result;
  }

  @override
  Future<int> size({K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var fc = fullCache;
    if (fc != null && isAllKey(k1, k2, k3, where))
      return fc.length;

    var distinct = where.distinct != null ? 'DISTINCT `${where.distinct}`' : '*';

    var sql = 'SELECT COUNT($distinct) FROM `${tableInfo.tableName}` ${w.v1}';

    int seq = sequence++;
    if (debug) Log.v(_TAG, () => '[$seq] final SQL: $sql, args: ${toPrintableArgs(w.v2, w.v3)}');

    var result = await db.rawQuery(sql, w.v2);

    if (debug) Log.d(_TAG, () => '[$seq] size() result: $result.');

    return result[0].values.first as int;
  }

  @override
  Future<void> forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, {K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) async {
    var all = await get(k1: k1, k2: k2, k3: k3, where: where);

    for (var val in all) {
      var r = processor(val);

      if (r is Future)
        r = await r;

      if (r == false)
        break;
    }
  }

  @override
  Stream<VALUE_TYPE> values({K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj, }) async* {
    var r = await get(k1: k1, k2: k2, k3: k3, where: where, whereObj: whereObj);
    for (var v in r) {
      yield v;
    }
  }

  @override
  Stream<KEY_TYPE> keys<KEY_TYPE>(String keyCol, { bool? withPkKeys, K1? k1, K2? k2, K3? k3, SqlWhereObj? where }) async* {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where,);

    where.columns = withPkKeys != false ? [...tableInfo.pk] : [keyCol];

    if (!where.columns!.contains(keyCol))
      where.columns!.add(keyCol);

    where.distinct = keyCol;

    var r = await getRawMap(where, transferMap: false);
    var trans = tableInfo.transformers[keyCol];

    for (var m in r) {
      var v = m[keyCol];
      yield (trans != null ? trans.fromSql(v) : v) as KEY_TYPE;
    }
  }

  @override
  Future<bool> isTableExists() async {
    var sql = 'SELECT COUNT(*) FROM sqlite_master WHERE type = ? AND name = ?';
    var args = ['table', tableName];
    var argNames = ['type', 'name'];
    if (debug) Log.v(_TAG, () => 'final SQL: $sql, args: ${toPrintableArgs(args, argNames)}');

    var result = await db.rawQuery(sql, args);
    return result[0].values.first as num > 0;
  }

  @override
  Future<void> createTable({ bool debugCheckInit = false, }) async {
    var exists = await isTableExists();

    if (!exists) {
      if (debugCheckInit) {
        throw SqliteDatabaseException('rebuild error', "Should update database version first, new db: $tableName.");
      }

      var sql = 'CREATE TABLE IF NOT EXISTS `$tableName`(${tableInfo.tableDefine()})';
      if (debug) Log.v(_TAG, () => 'final SQL: $sql');
      await db.execute(sql);
      await createIndexes();
    } else
      await updateTable(db, tableName, tableInfo, debugCheckInit: debugCheckInit);
  }


  Future<void> dropIndexes() async {
    if (tableInfo.indexes?.isNotEmpty == true) {
      for (var indexName in tableInfo.indexes!.keys) {
        await dropIndex(indexName);
      }
    }

    if (tableInfo.uniqueIndexes?.isNotEmpty == true) {
      for (var indexName in tableInfo.uniqueIndexes!.keys) {
        await dropIndex(indexName);
      }
    }
  }

  Future<void> dropIndex(String name) async {
    var sql = 'DROP INDEX IF EXISTS `$tableName`.`$name`';
    if (debug) Log.v(_TAG, () => 'final SQL: $sql');
    await db.execute(sql);
  }

  Future<void> createIndexes() async {
    if (tableInfo.indexes?.isNotEmpty == true) {
      for (var indexName in tableInfo.indexes!.keys) {
        var index = tableInfo.indexes![indexName]!;
        await createIndex(indexName, index, false);
      }
    }

    if (tableInfo.uniqueIndexes?.isNotEmpty == true) {
      for (var indexName in tableInfo.uniqueIndexes!.keys) {
        var index = tableInfo.uniqueIndexes![indexName]!;
        await createIndex(indexName, index, true);
      }
    }
  }

  Future<void> createIndex(String indexName, List<String> indexColumns, bool unique) async {
    var sql = 'CREATE ${unique == true ? "UNIQUE " : ""}INDEX IF NOT EXISTS `$indexName` ON `$tableName`(${indexColumns.join(',')})';
    if (debug) Log.v(_TAG, () => 'final SQL: $sql');
    await db.execute(sql);
  }

  @override
  Future<void> dropTable() {
    var sql = 'DROP TABLE IF EXISTS `$tableName`';
    if (debug) Log.v(_TAG, () => 'final SQL: $sql');
    return db.execute(sql);
  }

  @override
  Future<Map<String, SqlColumnDef>> readCols() async {
    var existed = <String, SqlColumnDef> { };
    var result = await db.rawQuery("PRAGMA TABLE_INFO('$tableName')");
    Log.d(_TAG, () => "table struct result: $result");

    if (result.length == 0)
      return existed;

    /*
    result format: {
      cid: 1...100,       // column index
      name: 'col name',   // column name
      type: 'TEXT',       // column type, eg: BLOB
      pk: 0/1,            // PrimaryKey, is part of the PRIMARY KEY
      notnull: 0/1,       // Has a NOT NULL constraint
      dflt_value: "123",  // default value of column.
    } */
    for (var col in result) {
      var name = col["name"] as String;
      existed[name] = SqlColumnDef(
          name: name,
          type: col["type"] as String,
          nullable: col['notnull'] == '1' || col['notnull'] == 1,
          defaultValue: col['dflt_value'],
      );
    }

    return existed;
  }

}
