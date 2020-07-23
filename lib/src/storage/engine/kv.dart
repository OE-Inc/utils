
import 'package:utils/src/storage/annotation/sql.dart';
import 'package:utils/src/storage/sql/table_info.dart';

import '../sqlike.dart';

class SqlTableImpKvStore<VALUE_TYPE, K1, K2, K3> extends SqlTableImp<VALUE_TYPE, K1, K2, K3> {

  SqlTableImpKvStore(SqlTableInfo<VALUE_TYPE> tableInfo) : super(tableInfo);

  @override
  Future<int> clear({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement clear
    throw UnimplementedError();
  }

  @override
  Future<bool> contains({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement contains
    throw UnimplementedError();
  }

  @override
  Future<bool> containsKey({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement containsKey
    throw UnimplementedError();
  }

  @override
  Future<void> createTable() {
    // TODO: implement createTable
    throw UnimplementedError();
  }

  @override
  Future<void> dropTable() {
    // TODO: implement dropTable
    throw UnimplementedError();
  }

  @override
  Future<VALUE_TYPE> first({K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE fallback}) {
    // TODO: implement first
    throw UnimplementedError();
  }

  @override
  Future<void> forEach(processor, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement forEach
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getRawMap(SqlWhereObj where) {
    // TODO: implement getRawMap
    throw UnimplementedError();
  }

  @override
  Future<void> invalidCache({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement invalidCache
    throw UnimplementedError();
  }

  @override
  Future<bool> isTableExists() {
    // TODO: implement isTableExists
    throw UnimplementedError();
  }

  @override
  Stream<VALUE_TYPE> keys(String keyCol, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement keys
    throw UnimplementedError();
  }

  @override
  Future<List<VALUE_TYPE>> remove({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement remove
    throw UnimplementedError();
  }

  @override
  Future<int> set(VALUE_TYPE val) {
    // TODO: implement set
    throw UnimplementedError();
  }

  @override
  Future<int> setField<FIELD_TYPE>(String field, FIELD_TYPE fieldVal, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement setFiled
    throw UnimplementedError();
  }

  @override
  Future<int> setFields(Map<String, dynamic> fields, {K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement setFileds
    throw UnimplementedError();
  }

  @override
  Future<int> size({K1 k1, K2 k2, K3 k3, SqlWhereObj where}) {
    // TODO: implement size
    throw UnimplementedError();
  }

  @override
  Future<int> update(VALUE_TYPE val) {
    // TODO: implement update
    throw UnimplementedError();
  }

  @override
  Stream<VALUE_TYPE> values({K1 k1, K2 k2, K3 k3, SqlWhereObj where, VALUE_TYPE whereObj, }) {
    // TODO: implement values
    throw UnimplementedError();
  }

  @override
  Future<Map<String, SqlColumnDef>> readCols() {
    // TODO: implement readCols
    throw UnimplementedError();
  }

}