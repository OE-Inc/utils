
import 'dart:async';

import 'package:path/path.dart';
import 'package:utils/util/running_env.dart';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:moor_flutter/moor_flutter.dart' as moor;

import 'moor_web_stub.dart'
 if (dart.library.js) 'package:moor/moor_web.dart' as moor_web;

import '../../error.dart';
import '../../log.dart';


/// Prototype of the function called when the version has changed.
///
/// Schema migration (adding column, adding table, adding trigger...)
/// should happen here.
typedef OnDatabaseVersionChangeFn = FutureOr<void> Function(
    SqliteDatabase db, int oldVersion, int newVersion);

/// Prototype of the function called when the database is created.
///
/// Database intialization (creating tables, views, triggers...)
/// should happen here.
typedef OnDatabaseCreateFn = FutureOr<void> Function(SqliteDatabase db, int version);


///
/// Common API for [Database] and [SqliteTransaction] to execute SQL commands
///
abstract class DatabaseRawExecutor {
  /// Execute an SQL query with no return value.
  ///
  /// ```
  ///   await db.execute(
  ///   'CREATE TABLE Test (id INTEGER PRIMARY KEY, name TEXT, value INTEGER, num REAL)');
  /// ```
  Future<void> execute(String sql, [List<Object>? arguments]);

  /// Executes a raw SQL INSERT query and returns the last inserted row ID.
  ///
  /// ```
  /// int id1 = await database.rawInsert(
  ///   'INSERT INTO Test(name, value, num) VALUES("some name", 1234, 456.789)');
  /// ```
  ///
  /// 0 could be returned for some specific conflict algorithms if not inserted.
  Future<int> rawInsert(String sql, [List<Object>? arguments]);

  /// Executes a raw SQL SELECT query and returns a list
  /// of the rows that were found.
  ///
  /// ```
  /// List<Map> list = await database.rawQuery('SELECT * FROM Test');
  /// ```
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object>? arguments]);

  /// Executes a raw SQL UPDATE query and returns
  /// the number of changes made.
  ///
  /// ```
  /// int count = await database.rawUpdate(
  ///   'UPDATE Test SET name = ?, value = ? WHERE name = ?',
  ///   ['updated name', '9876', 'some name']);
  /// ```
  Future<int> rawUpdate(String sql, [List<Object>? arguments]);

  /// Executes a raw SQL DELETE query and returns the
  /// number of changes made.
  ///
  /// ```
  /// int count = await database
  ///   .rawDelete('DELETE FROM Test WHERE name = ?', ['another name']);
  /// ```
  Future<int> rawDelete(String sql, [List<Object>? arguments]);
}


abstract class SqliteBatch {

  /// Commits all of the operations in this batch as a single atomic unit
  /// The result is a list of the result of each operation in the same order
  /// if [noResult] is true, the result list is empty (i.e. the id inserted
  /// the count of item changed is not returned.
  ///
  /// The batch is stopped if any operation failed
  /// If [continueOnError] is true, all the operations in the batch are executed
  /// and the failure are ignored (i.e. the result for the given operation will
  /// be a DatabaseException)
  ///
  /// During [Database.onCreate], [Database.onUpgrade], [Database.onDowngrade]
  /// (we are already in a transaction) or if the batch was created in a
  /// transaction it will only be commited when
  /// the transaction is commited ([exclusive] is not used then)
  Future<List<Object?>> commit(
      {bool exclusive, bool noResult, bool continueOnError});


  /// See [Database.rawInsert]
  void rawInsert(String sql, [List<Object>? arguments]);

  /// See [Database.rawDelete]
  void rawDelete(String sql, [List<Object>? arguments]);

  /*
  /// See [Database.rawUpdate]
  void rawUpdate(String sql, [List<Object>? arguments]);

  /// See [Database.execute];
  void execute(String sql, [List<Object>? arguments]);

  /// See [Database.query];
  void rawQuery(String sql, [List<Object>? arguments]);
   */

}


abstract class DatabaseExecutor extends DatabaseRawExecutor {

  /// Creates a batch, used for performing multiple operation
  /// in a single atomic operation.
  ///
  /// a batch can be commited using [SqliteBatch.commit]
  ///
  /// If the batch was created in a transaction, it will be commited
  /// when the transaction is done
  SqliteBatch batch();
}

abstract class SqliteTransaction extends DatabaseRawExecutor { }


abstract class SqliteDatabase extends DatabaseExecutor {

  String  name;
  late int version;

  SqliteDatabase(this.name);


  Future<SqliteDatabase> initialize(int latestVersion, { required OnDatabaseCreateFn onCreate, required OnDatabaseVersionChangeFn onUpgrade, });

  Future<T> transaction<T>(Future<T> Function(DatabaseRawExecutor txn) action,
      {bool exclusive});

  static SqliteDatabase getDb(String name) {
    return RunningEnv.isWeb ? MoorDb(name) : SqfliteDb(name);
  }

}

class SqfliteTransaction extends SqliteTransaction {

  sqflite.Transaction   trans;

  SqfliteTransaction(this.trans);

  @override
  Future<void> execute(String sql, [List<Object>? arguments]) {
    return trans.execute(sql, arguments);
  }

  @override
  Future<int> rawDelete(String sql, [List<Object>? arguments]) {
    return trans.rawDelete(sql, arguments);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object>? arguments]) {
    return trans.rawInsert(sql, arguments);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object>? arguments]) {
    return trans.rawQuery(sql, arguments);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object>? arguments]) {
    return trans.rawUpdate(sql, arguments);
  }

}

class SqfliteBatch extends SqliteBatch {

  sqflite.Batch   batch;

  SqfliteBatch(this.batch);

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError}) {
    return batch.commit(exclusive: exclusive, noResult: noResult, continueOnError: continueOnError);
  }

  @override
  void rawDelete(String sql, [List<Object>? arguments]) {
    return batch.rawDelete(sql, arguments);
  }

  @override
  void rawInsert(String sql, [List<Object>? arguments]) {
    return batch.rawInsert(sql, arguments);
  }

  /*
  @override
  void execute(String sql, [List<Object>? arguments]) {
    return batch.execute(sql, arguments);
  }

  @override
  void rawQuery(String sql, [List<Object>? arguments]) {
    return batch.rawQuery(sql, arguments);
  }

  @override
  void rawUpdate(String sql, [List<Object>? arguments]) {
    return batch.rawUpdate(sql, arguments);
  }
   */

}

class SqfliteDb extends SqliteDatabase {
  sqflite.Database? _db_;
  sqflite.Database get _db => _db_!;
  final _TAG = "SqfliteDb";

  SqfliteDb(String name): super(name);

  @override
  Future<SqliteDatabase> initialize(int latestVersion, { required OnDatabaseCreateFn onCreate, required OnDatabaseVersionChangeFn onUpgrade, }) async {
    assert(latestVersion != null);
    version = latestVersion;

    if (_db_ != null)
      return this;

    Log.i(_TAG, () => "initialize database start, version: $version");
    _db_ = await sqflite.openDatabase(
      join(await sqflite.getDatabasesPath(), name),
      onCreate: (db, version) async {
        _db_ = db;

        await onCreate(this, version);
      },
      onUpgrade: (db, oldVer, newVer) async {
        _db_ = db;

        Log.i(_TAG, () => "onUpgrade database: $oldVer => $newVer");

        await onUpgrade(this, oldVer, newVer);
      },

      version: version,
    )
        .catchError((e, stacktrace) {
      Log.w(_TAG, () => 'initDb error: ', e, stacktrace);
      throw e;
    });
    Log.i(_TAG, () => "initialize database complete.");

    return this;
  }

  @override
  SqliteBatch batch() => SqfliteBatch(_db.batch());

  @override
  Future<void> execute(String sql, [List<Object>? arguments]) {
    return _db.execute(sql, arguments);
  }

  @override
  Future<int> rawDelete(String sql, [List<Object>? arguments]) {
    return _db.rawDelete(sql, arguments);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object>? arguments]) {
    return _db.rawInsert(sql, arguments);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object>? arguments]) {
    return _db.rawQuery(sql, arguments);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object>? arguments]) {
    return _db.rawUpdate(sql, arguments);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseRawExecutor txn) action, {bool? exclusive}) {
    return _db.transaction((trans) => action(SqfliteTransaction(trans)), exclusive: exclusive);
  }
}


class MoorBatch extends SqliteBatch {

  moor.QueryExecutor _db;
  moor.BatchedStatements  batch = moor.BatchedStatements([], []);

  MoorBatch(this._db);

  @override
  Future<List<Object?>> commit({bool? exclusive, bool? noResult, bool? continueOnError}) async {
    await _db.runBatched(batch);
    return [];
  }

  void addSqlOp(String sql, [List<Object>? arguments]) {
    batch.statements.add(sql);
    batch.arguments.add(moor.ArgumentsForBatchedStatement(batch.arguments.length, arguments ?? []));
  }

  @override
  void rawDelete(String sql, [List<Object>? arguments]) {
    addSqlOp(sql, arguments);
  }

  @override
  void rawInsert(String sql, [List<Object>? arguments]) {
    addSqlOp(sql, arguments);
  }

}

mixin MoorQueryExecutorMixin on DatabaseRawExecutor {
  moor.QueryExecutor get exec;

  @override
  Future<void> execute(String sql, [List<Object>? arguments]) {
    return exec.runCustom(sql, arguments ?? []);
  }

  @override
  Future<int> rawDelete(String sql, [List<Object>? arguments]) {
    return exec.runDelete(sql, arguments ?? []);
  }

  @override
  Future<int> rawInsert(String sql, [List<Object>? arguments]) {
    return exec.runInsert(sql, arguments ?? []);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object>? arguments]) {
    return exec.runSelect(sql, arguments ?? []);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object>? arguments]) {
    return exec.runUpdate(sql, arguments ?? []);
  }

}

class MoorQueryExecutor extends SqliteDatabase with MoorQueryExecutorMixin {
  moor.QueryExecutor exec;

  MoorQueryExecutor(this.exec, String name) : super(name);

  @override
  SqliteBatch batch() {
    throw UnsupportedError("MoorQueryExecutor should never do batch().");
  }

  @override
  Future<SqliteDatabase> initialize(int latestVersion, { required OnDatabaseCreateFn onCreate, required OnDatabaseVersionChangeFn onUpgrade}) {
    throw UnsupportedError("MoorQueryExecutor should never do initialize().");
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseRawExecutor txn) action, {bool? exclusive}) {
    throw UnsupportedError("MoorQueryExecutor should never do transaction().");
  }
}

class MoorTransaction extends SqliteTransaction with MoorQueryExecutorMixin {
  moor.TransactionExecutor trans;

  MoorTransaction(this.trans);

  @override
  moor.QueryExecutor get exec => trans;

}

/*
class MoorDbImp extends moor.GeneratedDatabase {

  MoorDbImp(moor.SqlTypeSystem types, moor.QueryExecutor executor) : super(types, executor);

  @override
  Iterable<moor.TableInfo<moor.Table, dynamic>> get allTables => throw UnimplementedError();

  @override
  int get schemaVersion => throw UnimplementedError();

}

 */

extension OpeningDetailsExt on moor.OpeningDetails {

  String toStringDetail() {
    return "$runtimeType { versionBefore: $versionBefore, versionNow: $versionNow, }";
  }

}

class MoorDb extends SqliteDatabase with MoorQueryExecutorMixin implements moor.QueryExecutorUser {
  late moor.QueryExecutor _db;
  late OnDatabaseCreateFn onCreate;
  late OnDatabaseVersionChangeFn onUpgrade;
  final _TAG = "MoorDb";

  MoorDb(String name) : super(name);


  @override
  moor.QueryExecutor get exec => _db;

  @override
  Future<SqliteDatabase> initialize(int latestVersion, { required OnDatabaseCreateFn onCreate, required  OnDatabaseVersionChangeFn onUpgrade}) async {
    version = latestVersion;
    Log.i(_TAG, () => "initialize database start, version: $version");

    this.onCreate = onCreate;
    this.onUpgrade = onUpgrade;

    _db = RunningEnv.isWeb
      ? moor_web.WebDatabase(name) as moor.QueryExecutor
      : moor.FlutterQueryExecutor.inDatabaseFolder(path: name)
    ;

    await _db.ensureOpen(this);
    return this;
  }


  @override
  SqliteBatch batch() {
    return MoorBatch(_db);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(DatabaseRawExecutor txn) action, {bool? exclusive}) async {
    var executor = _db.beginTransaction();
    try {
      if (!await executor.ensureOpen(this))
        throw SqliteDatabaseException(null, 'ensureOpen() failed.');

      var result = await action(MoorTransaction(executor));
      await executor.send();  // commit.

      return result;
    } catch (e) {
      await executor.rollback();

      // Log.e(_TAG, () => "transaction error: ", e);
      rethrow;
    }
  }

  @override
  Future<void> beforeOpen(moor.QueryExecutor executor, moor.OpeningDetails details) async {
    Log.i(_TAG, () => "beforeOpen database details: ${details.toStringDetail()}, executor: $executor.");

    await executor.ensureOpen(this);

    Log.i(_TAG, () => "beforeOpen database executor opened.");

    var oldVer = details.versionBefore;
    var newVer = details.versionNow;
    var exec = MoorQueryExecutor(executor, name);

    if (oldVer == null) {
      await onCreate(exec, newVer);
    }

    if (oldVer != null && oldVer != newVer) {
      await onUpgrade(exec, oldVer, newVer);
    }
  }

  @override
  int get schemaVersion => version;

}

class SqliteDatabaseException extends ExceptionWithMessage<dynamic> {
  SqliteDatabaseException(dynamic error, String msg) : super(msg, data: error);

  bool isSyntaxError() {
    var err = data;
    if (err is sqflite.DatabaseException) return err.isSyntaxError();
    else return '$err'.contains('syntax error');
  }

  @override
  String toString() {
    return "$runtimeType { error: $data, msg: $msg, }";
  }
}
