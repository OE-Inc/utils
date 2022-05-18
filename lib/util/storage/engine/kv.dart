
import 'dart:async';

import 'package:utils/util/simple_interface.dart';
import 'package:utils/util/storage/annotation/sql.dart';
import 'package:utils/util/storage/sql/table_info.dart';

import '../sqlike.dart';

class SqlTableImpKvStore<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3> extends SqlTableImp<VALUE_TYPE, VALUE_TYPE_PARTIAL, K1, K2, K3> {

  SqlTableImpKvStore(SqlTableInfo<VALUE_TYPE, VALUE_TYPE_PARTIAL> tableInfo) : super(tableInfo);

  @override
  Future<int> clear({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement clear
    throw UnimplementedError();
  }

  @override
  Future<bool> contains({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  Future<bool> containsKey({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement containsKey
    throw UnimplementedError();
  }

  @override
  Future<void> createTable({ bool debugCheckInit = false, }) {
    // TODO: implement createTable
    throw UnimplementedError();
  }

  @override
  Future<void> dropTable() {
    // TODO: implement dropTable
    throw UnimplementedError();
  }

  @override
  Future<VALUE_TYPE?> first({K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE? fallback}) {
    // TODO: implement first
    throw UnimplementedError();
  }

  @override
  Future<void> forEach(Callable1<VALUE_TYPE, FutureOr<bool>> processor, {K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement forEach
    throw UnimplementedError();
  }

  @override
  Future<void> invalidCache(K1? k1, K2? k2, K3? k3, SqlWhereObj? where) {
    // TODO: implement invalidCache
    throw UnimplementedError();
  }

  @override
  Future<bool> isTableExists() {
    // TODO: implement isTableExists
    throw UnimplementedError();
  }

  @override
  Stream<KEY_TYPE> keys<KEY_TYPE>(String keyCol, {bool? withPkKeys, K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement keys
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> multiGetRawMap(Iterable<SqlWhereObj> where, {bool transferMap = true}) {
    // TODO: implement multiGetRawMap
    throw UnimplementedError();
  }

  @override
  Future<int> multiRemove(Iterable<SqlWhereObj> values) {
    // TODO: implement multiRemove
    throw UnimplementedError();
  }

  @override
  Future<int> multiSet(Iterable<VALUE_TYPE> values, {bool allowReplace = true}) {
    // TODO: implement multiSet
    throw UnimplementedError();
  }

  @override
  Future<Map<String, SqlColumnDef>> readCols() {
    // TODO: implement readCols
    throw UnimplementedError();
  }

  @override
  Future<List<VALUE_TYPE>> remove({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<int> set(VALUE_TYPE val, {bool allowReplace = true}) {
    // TODO: implement set
    throw UnimplementedError();
  }

  @override
  Future<int> setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, {K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement setField
    throw UnimplementedError();
  }

  @override
  Future<int> setFields(Map<String, dynamic> fields, {K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement setFields
    throw UnimplementedError();
  }

  @override
  Future<int> size({K1? k1, K2? k2, K3? k3, SqlWhereObj? where}) {
    // TODO: implement size
    throw UnimplementedError();
  }

  @override
  Future<int> update(VALUE_TYPE val) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Stream<VALUE_TYPE> values({K1? k1, K2? k2, K3? k3, SqlWhereObj? where, VALUE_TYPE_PARTIAL? whereObj}) {
    // TODO: implement values
    throw UnimplementedError();
  }

}
