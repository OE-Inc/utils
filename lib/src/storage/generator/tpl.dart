

import 'package:utils/src/storage/annotation/sql.dart';
import 'package:utils/src/storage/sql/table_info.dart';
import 'package:utils/src/storage/sqlike.dart';

// REMOVE START
// all text below and above 'GENERATION START' will be removed.
class __FIELD_TYPE__ { }
class __COL_TYPE__ { }
class __FIELD_TYPE_CK1__ { }
class __FIELD_TYPE_CK2__ { }
const __PK_LIST__ = null;
const __CK_COUNT__ = null;

class __MODEL_CLASS__ {
  __FIELD_TYPE__ PK_VAL__;
  __FIELD_TYPE__ PK_NO_CK_VAL__;

  __FIELD_TYPE__ CK_VAL__;

  __FIELD_TYPE__ NK_VAL__;
}

// all text above and starts from 'REMOVE START' will be removed.

// GENERATION START

extension __MODEL_CLASS__OrmExt on __MODEL_CLASS__ {

  Map<String, dynamic> toJson({ SqlTableInfo info, bool toJson = false }) {
    Map<String, dynamic> m = {
      "PK_VAL__": this.PK_VAL__,
      "NK_VAL__": this.NK_VAL__,
    };

    if (toJson) {
      info = info ?? __MODEL_CLASS__TableInfo.builder;
    }

    if (info != null) {
      m = info.toSqlTransferMap(m, toJson: toJson);
    }

    return m;
  }

  void fromJson(Map<String, dynamic> m, { bool defaultNull = false, SqlTableInfo info, bool fromJson = false }) {
    if (fromJson) {
      info = info ?? __MODEL_CLASS__TableInfo.builder;
    }

    if (info != null) {
      m = info.fromSqlTransferMap(m, fromJson: fromJson);
    }

    this.PK_VAL__ = m["PK_VAL__"] ?? (defaultNull ? null : this.PK_VAL__);
    this.NK_VAL__ = m["NK_VAL__"] ?? (defaultNull ? null : this.NK_VAL__);
  }

  __MODEL_CLASS__ clone({
    __FIELD_TYPE__ PK_VAL__,

    __FIELD_TYPE__ NK_VAL__,
  }) {
    var obj = __MODEL_CLASS__();
    obj.PK_VAL__ = PK_VAL__ ?? this.PK_VAL__;
    obj.NK_VAL__ = NK_VAL__ ?? this.NK_VAL__;
    return obj;
  }

}


class __MODEL_CLASS__TableInfo extends SqlTableInfo<__MODEL_CLASS__> {

  static __MODEL_CLASS__TableInfo builder = __MODEL_CLASS__TableInfo(__MODEL_CLASS__());

  __MODEL_CLASS__TableInfo(__MODEL_CLASS__ template, { String tableName }): super(tableName ?? "__TABLE_NAME__", __PK_LIST__, __CK_COUNT__, template);

  __MODEL_CLASS__ makeObj({
    __FIELD_TYPE__ PK_VAL__,

    __FIELD_TYPE__ NK_VAL__,
  }) {
    var obj = __MODEL_CLASS__();

    obj.PK_VAL__ = PK_VAL__;

    obj.NK_VAL__ = NK_VAL__;

    return obj;
  }

  @override
  SqlWhereObj getWhere(__MODEL_CLASS__ part, bool withPk, bool excludeCk, bool withNk, { SqlWhereObj where, }) {
    where = where ?? SqlWhereObj();

    if (withPk) {
      if (excludeCk) {
        if (part.PK_NO_CK_VAL__ != null) where.compared(SqlWhereItem.OP_EQUAL, "PK_NO_CK_VAL__", part.PK_NO_CK_VAL__);
      } else {
        if (part.PK_VAL__ != null) where.compared(SqlWhereItem.OP_EQUAL, "PK_VAL__", part.PK_VAL__);
      }
    }

    if (withNk) {
      if (part.NK_VAL__ != null) where.compared(SqlWhereItem.OP_EQUAL, "NK_VAL__", part.NK_VAL__);
    }

    return where;
  }

  @override
  fillTemplateKeys(__MODEL_CLASS__ part, bool withPk, bool excludeCk) {
    if (withPk) {
      if (excludeCk) {
        part.PK_NO_CK_VAL__ = template.PK_NO_CK_VAL__;
      } else {
        part.PK_VAL__ = template.PK_VAL__;
      }
    }
  }

  @override
  Map<String, SqlColumnDef> makeColumnDefine() {
    const table = "__TABLE_NAME__";
    return {
      "PK_VAL__": SqlColumnDef<__COL_TYPE__, __FIELD_TYPE__>(name: "PK_VAL__", type: "__COL_TYPE_AND_DEF__", table: table),

      "NK_VAL__": SqlColumnDef<__COL_TYPE__, __FIELD_TYPE__>(name: "NK_VAL__", type: "__COL_TYPE_AND_DEF__", table: table),
    };
  }

  @override
  __MODEL_CLASS__ fromSql(Map<String, dynamic> cols) {
    var obj = __MODEL_CLASS__();
    obj.fromJson(cols);
    return obj;
  }

  @override
  Map<String, dynamic> toSql(__MODEL_CLASS__ val) {
    return val.toJson();
  }
}

// GENERATION END


// GENERATION TABLE 1N START
class __MODEL_CLASS__Table1N extends SqlTable1N<__FIELD_TYPE_CK1__, __MODEL_CLASS__, __MODEL_CLASS__TableInfo> {
  __MODEL_CLASS__Table1N(__MODEL_CLASS__ template, [String tableName]) : super(__MODEL_CLASS__TableInfo(template, tableName: tableName));
}

// GENERATION TABLE 1N END

// GENERATION TABLE NN START
class __MODEL_CLASS__TableNN extends SqlTableNN<__FIELD_TYPE_CK1__, __FIELD_TYPE_CK2__, __MODEL_CLASS__, __MODEL_CLASS__TableInfo> {
  __MODEL_CLASS__TableNN(__MODEL_CLASS__ template, [String tableName]) : super(__MODEL_CLASS__TableInfo(template, tableName: tableName));
}

// GENERATION TABLE NN END
