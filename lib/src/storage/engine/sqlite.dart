

import 'dart:async';

import 'package:utils/src/running_env.dart';
import 'package:utils/src/simple_interface.dart';
import 'package:utils/src/storage/annotation/sql.dart';
import 'package:utils/src/storage/index.dart';
import 'package:utils/src/storage/sql/table_info.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../log.dart';
import '../sqlike.dart';

const String _TAG = 'SqlTableImpSqlite';

class DatabaseProvider {
  Database  _db;

  Map<String, Callable1<void, Future<void>>> tables = { };

  List<Callable2<Database, int, void>> onCreates = [];
  List<Callable3<Database, int, int, void>> onUpgrades = [];

  DatabaseProvider();

  bool isInitialized() => _db != null;

  Database getDb() {
    if (_db == null)
      throw Exception("Should always call databaseProvider.initialize() when startup.");

    return _db;
  }

  Future<void> initTables() async {
    Log.i(_TAG, "creating tables: ${tables.keys}");

    for (var table in tables.keys) {
      Log.i(_TAG, "creating table: $table");
      await tables[table](null);
    }
  }


  Future<Database> initialize([int latestVersion]) async {
    if (_db != null)
      return _db;

    var version = latestVersion ?? 20200714;

    Log.i(_TAG, "initialize database start, version: $version");
    _db = await openDatabase(
      join(await getDatabasesPath(), 'main.db'),
      onCreate: (db, version) async {
        _db = db;

        Log.i(_TAG, "onCreate database $version");

        await initTables();

        for (var oc in onCreates)
          oc(db, version);
      },
      onUpgrade: (db, oldVer, newVer) async {
        _db = db;

        Log.i(_TAG, "onUpgrade database: $oldVer => $newVer");

        await initTables();

        for (var ou in onUpgrades)
          ou(db, oldVer, newVer);
      },

      version: version,
    )
        .catchError((e, stacktrace) {
      Log.w(_TAG, 'initDb error: $e, $stacktrace');
      throw e;
    });
    Log.i(_TAG, "initialize database complete.");

    return _db;
  }
}

final DatabaseProvider databaseProvider = DatabaseProvider();

class SqlTableImpSqlite<VALUE_TYPE, K1, K2, K3> extends SqlTableImp<VALUE_TYPE, K1, K2, K3> {
  bool debug = RunningEnv.isDebug || false;

  Database get db => dbProvider.getDb();
  DatabaseProvider dbProvider;

  SqlTableImpSqlite(SqlTableInfo<VALUE_TYPE> tableInfo, { this.dbProvider }) : super(tableInfo) {
    dbProvider = dbProvider ?? databaseProvider;

    if (dbProvider.isInitialized() && !dbProvider.tables.containsKey(tableName)) {
      Log.e(_TAG, "database already initialized before table created, table may not created/updated.");
    }

    dbProvider.tables[tableName] = (_void) => createTable();
  }

  static Future<void> updateTable(Database db, String table, Map<String, SqlColumnDef> columns) async {
    var existed = <String, String> { };
    var result = await db.rawQuery("PRAGMA TABLE_INFO('$table')");
    print("table struct result: $result");

    if (result.length == 0)
      return;

    for (var col in result) {
      existed[col["name"]] = col["type"];
    }

    for (var col in columns.keys) {
      var colType = columns[col].type;
      var existedType = existed[col];

      if (existedType != null) {
        if (existedType.toLowerCase() != colType.toLowerCase())
          throw UnsupportedError("Not support table column($col) type change: $existedType(existed) => $colType(new).");

        continue;
      }

      var sql = "ALTER TABLE `$table` ADD `$col` $colType";

      Log.v(_TAG, 'final SQL: $sql');

      await db.execute(sql);
    }
  }

  @override
  Future<int> clear({K1 k1, K2 k2, K3 k3, SqlWhereObj where }) {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo, withWhereWord: false);

    if (debug) Log.v(_TAG, 'clear table: $tableName.');

    return db.delete(tableName, where: w.f, whereArgs: w.s);
  }

  @override
  Future<bool> contains({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async {
    return (await size(k1: k1, k2: k2, k3: k3, where: where)) > 0;
  }

  @override
  Future<bool> containsKey({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async {
    return (await size(k1: k1, k2: k2, k3: k3, where: where)) > 0;
  }

  List toPrintableArgs(List args) {
    return args.map((a) => a is Uint8List ? a.hexString() : a).toList();
  }

  List toPrintableResults(List<Map> args) {
    return args.map((m) {
      Map copied;

      for (var k in m.keys) {
        var v = m[k];

        if (v is Uint8List) {
          copied = copied ?? Map.from(m);
          copied[k] = v.hexString();
        }
      }

      return copied ?? m;
    }).toList();
  }

  @override
  Future<VALUE_TYPE> first({K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE fallback}) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    where.limit = 1;

    var result = await getRaw(where);

    if (debug) Log.d(_TAG, 'first() result: $result.');

    return result.isNotEmpty ? result[0]??fallback : fallback;
  }

  @override
  Future<List<Map<String, dynamic>>> getRawMap(SqlWhereObj where) async {
    var w = where.finalWhere(tableInfo);

    var sel = (where.columns?.isNotEmpty??true ? '*' : where.columns.map((c) => '`$c`').join(','));
    var distinct = where.distinct != null ? 'DISTINCT ' : '';

    var sql = 'SELECT $distinct$sel FROM `$tableName` ${w.f}';
    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(w.s)}');

    var result = await db.rawQuery(sql, w.s);

    if (debug) Log.d(_TAG, 'getRaw() result: ${toPrintableResults(result)}.');

    if (result.isEmpty)
      return [];

    return result.map((r) => tableInfo.fromSqlTransferMap(r)).toList();
  }

  @override
  Future<void> invalidCache({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async {
    // TODO: should check for keys.
    cached.clear();
  }

  @override
  Future<List<VALUE_TYPE>> remove({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var existed = await get(k1: k1, k2: k2, k3: k3, where: where);

    var sql = 'DELETE FROM `$tableName` ${w.f}';
    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(w.s)}');

    await db.execute(sql, w.s);

    return existed;
  }

  @override
  Future<int> set(VALUE_TYPE val, { bool allowReplace = true, }) async {
    var saved = tableInfo.toSqlTransfer(val);
    var keys = saved.keys.toList();

    var ins = (allowReplace ? "INSERT OR REPLACE INTO" : "INSERT INTO");

    var sql = '$ins `$tableName` (${keys.map((f) => '`$f`').join(',')}) VALUES (${keys.map((f) => '?').join(',')})';
    var args = keys.map((e) => saved[e]).toList();

    if (debug) Log.v(_TAG, 'final SQL: $sql，args: ${toPrintableArgs(args)}');

    var result = await db.rawInsert(sql, args);

    if (debug) Log.d(_TAG, 'set() result: $result.');

    return result;
  }

  Future<int> update(VALUE_TYPE val) async {
    var saved = tableInfo.toSqlTransfer(val, excludePk: true);
    var keys = saved.keys.toList();
    var where = getWhere(val, true, true, false);
    var w = where.finalWhere(tableInfo);

    var args = [...keys.map((k) => saved[k]), ...w.s];

    var sql = 'UPDATE `$tableName` SET ${keys.map((c) => '`$c`=?').join(',')} WHERE ${w.f}';
    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(args)}');

    var result = await db.rawUpdate(sql, args);

    if (debug) Log.d(_TAG, 'update() result: $result.');

    return result;
  }

  @override
  Future<int> setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var sql = 'UPDATE `$tableName` SET `$field`=? ${w.f}';
    var args =  [tableInfo.columns[field].toSql(fieldVal), ...w.s];

    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(args)}');

    return db.rawUpdate(sql, args);
  }

  @override
  Future<int> setFields(Map<String, dynamic> fields, { K1 k1, K2 k2, K3 k3, SqlWhereObj where, }) {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var args = [];
    var sets = fields.keys.map((f) {
      var v = fields[f];
      if (v == null)
        return null;
      
      args.add(tableInfo.columns[f].toSql(v));
      return '`$f`=?';
    }).where((s) => s != null).join(',');

    var sql = 'UPDATE `$tableName` SET $sets ${w.f}';
    args = [...args, ...w.s];

    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(args)}');

    return db.rawUpdate(sql, args);
  }

  @override
  Future<int> size({K1 k1, K2 k2, K3 k3, SqlWhereObj where }) async {
    where = mergeWhere(k1: k1, k2: k2, k3: k3, where: where);
    var w = where.finalWhere(tableInfo);

    var distinct = where.distinct != null ? 'DISTINCT `${where.distinct}`' : '*';

    var sql = 'SELECT COUNT($distinct) FROM `${tableInfo.tableName}` ${w.f}';

    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(w.s)}');

    var result = await db.rawQuery(sql, w.s);

    if (debug) Log.d(_TAG, 'size() result: $result.');

    return result[0].values.first;
  }

  @override
  Future<void> forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async {
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
  Stream<VALUE_TYPE> values({K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE whereObj, }) async* {
    var r = await get(k1: k1, k2: k2, k3: k3, where: where, whereObj: whereObj);
    for (var v in r) {
      yield v;
    }
  }

  @override
  Stream<VALUE_TYPE> keys(String keyCol, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) async* {
    if (where == null) {
      where = SqlWhereObj();
    }

    where.columns = [...tableInfo.pk];

    if (!tableInfo.pk.contains(keyCol))
      where.columns.add(keyCol);

    var r = await get(k1: k1, k2: k2, k3: k3, where: where);
    for (var v in r) {
      yield v;
    }
  }

  Future<bool> isTableExists() async {
    var sql = 'SELECT COUNT(*) FROM sqlite_master WHERE type = ? AND name = ?';
    var args = ['table', tableName];
    if (debug) Log.v(_TAG, 'final SQL: $sql, args: ${toPrintableArgs(args)}');

    var result = await db.rawQuery(sql, args);
    return result[0].values.first > 0;
  }

  Future<void> createTable() async {
    var exists = await isTableExists();

    if (!exists) {

      var sql = 'CREATE TABLE IF NOT EXISTS `$tableName`(${tableInfo.tableDefine()})';
      if (debug) Log.v(_TAG, 'final SQL: $sql');
      return db.execute(sql);
    }

    await updateTable(db, tableName, tableInfo.columns);
  }

  Future<void> dropTable() {
    var sql = 'DROP TABLE IF EXISTS `$tableName`';
    if (debug) Log.v(_TAG, 'final SQL: $sql');
    return db.execute(sql);
  }

  Future<Map<String, SqlColumnDef>> readCols() async {
    var existed = <String, SqlColumnDef> { };
    var result = await db.rawQuery("PRAGMA TABLE_INFO('$tableName')");
    print("table struct result: $result");

    if (result.length == 0)
      return existed;

    for (var col in result) {
      existed[col["name"]] = SqlColumnDef(
          name: col['name'],
          type: col["type"],
          nullable: col['notnull'] == '1' || col['notnull'] == 1,
          defaultValue: col['dflt_value'],
      );
    }

    return existed;
  }

}
