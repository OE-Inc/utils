/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:utils/util/source_gen/generator/source_gen_ext.dart';
import 'package:utils/util/storage/annotation/sql.dart';
import 'package:utils/util/storage/sql/table_info.dart';
import 'package:utils/util/utils.dart';

const _debug = false;

class SimpleTableInfo extends SqlTableInfo {
  List<FieldElement>   fields;

  SimpleTableInfo(this.fields, String tableName, List<String> pk, int ckCount, template, { Map<String, List<String>>? indexes, Map<String, List<String>>? uniqueIndexes }) : super(tableName, pk, ckCount, template, indexes: indexes, uniqueIndexes: uniqueIndexes, );

  static const excludeFields = ['hashCode', 'runtimeType', 'equals'];

  static SqlTransformer parseTransformerType(SqlTransformer? transformer, FieldElement f) {
    if (transformer != null) {
      return transformer;
    }

    var type = f.type;
    if (type.isAssignableTypeOf(SqlSerializable)) {
      // type = f.returnTypeOfMethod("toSave");
      return SqlTransformer.sqlSerializable;
    }

    if (type.isDartCoreInt
        || type.isDartCoreBool
        || type.isDartCoreNum
        || type.isDartCoreString
        || type.isType(Uint8List)
    )
      return SqlTransformer.raw;

    else if (type.isDartCoreList
      || type.isDartCoreMap)
      return SqlTransformer.json;
    else if (type.isType(Int64))
      return SqlTransformer.int64;

    throw IllegalArgumentException("Should never provide a invalid col/field when parseTransformerType(), field: $f, type: $type");
  }

  static String parseFinalFieldType(SqlColumnDef? col, FieldElement f) {
    DartType type = f.type;

    SqlTransformer? transformer = col?.transformer;

    if (transformer != null) {
      switch (transformer) {
        case SqlTransformer.base64:
        case SqlTransformer.json:
        case SqlTransformer.hex:
          return 'String';

        case SqlTransformer.raw:
        case SqlTransformer.sqlSerializable:
          break;

        default:
          throw IllegalArgumentException("Not support SqlColumnDef for transformer: ${col?.transformer}.");
          break;
      }
    }

    if (type.isAssignableTypeOf(SqlSerializable)) {
      type = f.returnTypeOfMethod("toSave")!;
    }

    if (type.isDartCoreInt || f.type.isDartCoreBool) return 'int';
    else if (type.isType(Int64)) return "Int64";
    else if (type.isType(BigInt)) return "BigInt";
    else if (type.isDartCoreNum) return "double";
    else if (type.isDartCoreString) return "String";

    else if (type.isDartCoreList) return "String";
    else if (type.isDartCoreMap)  return "String";

    else if (type.isType(Uint8List)) return "Uint8List";

    return '$type';
  }

  static String parseColType(SqlColumnDef? col, FieldElement f) {
    var type = f.type;

    if (col != null) {
      if (col.type != null) {
        return col.type!;
      }

      SqlTransformer? transformer = col.transformer;

      if (transformer != null) {
        switch (transformer) {
          case SqlTransformer.base64:
          case SqlTransformer.json:
          case SqlTransformer.hex:
            return "TEXT";

          case SqlTransformer.sqlSerializable:
          case SqlTransformer.raw:
            break;

          default:
            throw IllegalArgumentException("Not support SqlColumnDef for tranformer: ${col.transformer}.");
            break;
        }
      }
    }

    if (type.isAssignableTypeOf(SqlSerializable)) {
      type = f.returnTypeOfMethod("toSave")!;
    }

    /// Supported SQLite types of 'sqflite':
    /// INTEGER <=> int
    /// REAL    <=> num
    /// TEXT    <=> String
    /// BLOB    <=> Uint8List

    if (type.isDartCoreInt || f.type.isDartCoreBool) return "INTEGER";
    else if (type.isType(Int64) || type.isType(BigInt)) return "TEXT";
    else if (type.isDartCoreNum) return "REAL";
    else if (type.isDartCoreString) return "TEXT";

    else if (type.isDartCoreList) return "TEXT";
    else if (type.isDartCoreMap)  return "TEXT";

    else if (type.isType(Uint8List)) return "BLOB";

    throw IllegalArgumentException("Should never provide a invalid col/field when parseColType(), col: $col, field: $f, type: $type");
  }

  static SqlTransformer getTransformerEnum(DartObject map, FieldElement f) {
    var val = map.getField('transformer');
    if (val == null || val.isNull) {
      if (f.type.isAssignableTypeOf(SqlSerializable)) {
        return SqlTransformer.sqlSerializable;
      }

      return parseTransformerType(null, f);
    }

    print("SqlColumnDef meta: $map, transformer: ${map.getField('transformer')}/${map.getField('transformer')?.type}");
    var ft = map.getField('transformer');
    var str = ft.toString();
    var enumIndex = int.parse(str.substring(str.lastIndexOf('(', ) + 1, str.lastIndexOf('))')));

    // print("values: ${ft.toStringValue()}, ${ft.toTypeValue()}, ${ft.toSymbolValue()}, ${ft.toString()}, index: $enumIndex");

    var transEnum = SqlTransformer.values.firstWhere((e) => e.index == enumIndex);

    if (f.type.isAssignableTypeOf(SqlSerializable) && transEnum != SqlTransformer.sqlSerializable)
      throw IllegalArgumentException("A SqlSerializable should always set transformer = SqlTransformer.sqlSerializable");

    return transEnum;
  }

  @override
  Map<String, SqlColumnDef> makeColumnDefine() {
    Map<String, SqlColumnDef> map = {};

    for (var f in fields) {
      if (_debug) print("checking field: ${f.name}/${f.type.getDisplayString(withNullability: true)}, $f, meta: ${f.metadata}");

      if (f.isConst || f.isFinal || f.isStatic) {
        if (!pk.contains(f.name)) {
          continue;
        }
      }

      if (excludeFields.contains(f.name))
        continue;

      if (f.firstMeta(IgnoredColumn) != null || f.hasDoNotStore)
        continue;

      if (f.setter == null)
        continue;

      SqlColumnDef? def;
      var sqlDef = f.firstMeta(SqlColumnDef);
      if (sqlDef != null) {
        var map = sqlDef.computeConstantValue()!;

        def = SqlColumnDef(
          table: map.getFieldStringValue('table'),
          name: map.getFieldStringValue('name') ?? f.name,
          type: map.getFieldStringValue('type') ?? parseColType(def, f),
          defaultValue: map.getFieldStringValue('defaultValue'),
          nullable: map.getField('nullable')?.toBoolValue() ?? SqlColumnDef.DEFAULT_NULLABLE,
          oldName: map.getFieldStringValue('oldName'),
          transformer: getTransformerEnum(map, f),

          lazyRestore: map.getField('lazyRestore')?.toBoolValue(),
        );

        print('user defined SqlColumnDef: $def, from: $map.');
      }

      String type = parseColType(def, f);
      if (_debug) print("parseColType: $type, from fieldType: ${f.type}.");

      if (def == null) {
        def = SqlColumnDef(
            table: null,
            name: f.name,
            type: type,

            field: f.name,
            fieldType: '${f.noneNullType}',
            finalType: parseFinalFieldType(def, f),

            transformer: parseTransformerType(null, f)
        );
      } else {
        def = SqlColumnDef(
          table: def.table,
          name: def.name ?? f.name,
          oldName: def.oldName,
          type: def.type ?? type,

          field: f.name,
          fieldType: '${f.noneNullType}',
          finalType: parseFinalFieldType(def, f),

          defaultValue: def.defaultValue,
          nullable: def.nullable,
          transformer: def.transformer,
          // transfer: transfer,

          lazyRestore: def.lazyRestore,
        );
      }

      map[def.name!] = def;
    }

    return map;
  }

  @override
  fillTemplateKeys(part, bool withPk, bool withCk) {
    throw UnimplementedError();
  }

  @override
  SqlWhereObj getWhere(part, bool withPk, bool withCk, bool withNk, {SqlWhereObj? where}) {
    throw UnimplementedError();
  }

  @override
  fromSql(Map<String, dynamic> cols) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toSql(val) {
    throw UnimplementedError();
  }

  @override
  toPartial(part) {
    throw UnimplementedError();
  }
}


//BuildStep resolver;

/// all are function names that may conflict with field name when in extension.
const Set excludedFields = { 'utc', 'delay', 'repeat', 'concat' };

SimpleTableInfo parseTableInfo(ClassElement element, ConstantReader annotation, BuildStep buildStep) {
  var className = element.name;
  var fields = element.fields;
  element.allSupertypes.forEach((s) {
    if (_debug) print("checking super: coreObj: ${s.isDartCoreObject}, $s.");
    if (s.isDartCoreObject)
      return;

    fields.addAll(s.element.fields);
  });

  var tableName = annotation.read('tableName').stringValue;
  var ckCount = annotation.read('collectionKeyCount').intValue;
  var indexes = annotation.read('indexes').isMap
      ? annotation.read('indexes').mapValue
        .map((key, value) => MapEntry("${key!.toStringValue()}", value!.toListValue()!.map((e) => e.toStringValue()!).toList()))
      : null;

  var uniqueIndexes = annotation.read('uniqueIndexes').isMap
      ? annotation.read('uniqueIndexes').mapValue
        .map((key, value) => MapEntry("${key!.toStringValue()}", value!.toListValue()!.map((e) => e.toStringValue()!).toList()))
      : null;

  var pk = List<String>.from(annotation.read('primaryKeys').listValue.map((s) => s.toStringValue()));

  for (var p in pk) {
    if (!fields.any((f) => p == f.name))
      throw IllegalArgumentException("$className not exist pk: '$p', pks: $pk");
  }

  var tableInfo = SimpleTableInfo(fields, tableName, pk, ckCount, null, indexes: indexes, uniqueIndexes: uniqueIndexes);
  print('parsed table info: $tableInfo');

  return tableInfo;
}

String generate(String className, SimpleTableInfo tableInfo, String template) {
  var tableName = tableInfo.tableName;
  var ckCount = tableInfo.ck.length;
  var pk = tableInfo.pk;
  var fields = tableInfo.fields;
  var indexes = tableInfo.indexes;
  var uniqueIndexes = tableInfo.uniqueIndexes;

  List<List<String>> stringReplaced = [
    ["__MODEL_CLASS__", className],
    ["__TABLE_NAME__", tableName],
    ["__PK_LIST__", "${pk.map((p) => "'$p'").toList()}"],
    ["__CK_COUNT__", "$ckCount"],
    ["__INDEXES__", indexes?.isNotEmpty == true ? jsonEncode(indexes) : "null"],
    ["__UNIQUE_INDEXES__", uniqueIndexes?.isNotEmpty == true ? jsonEncode(uniqueIndexes) : "null"],
  ];

  if (ckCount > 0)
    stringReplaced.add(["__FIELD_TYPE_CK1__", fields.firstWhere((f) => f.name == tableInfo.ck[0]).noneNullType]);

  if (ckCount > 1)
    stringReplaced.add(["__FIELD_TYPE_CK2__", fields.firstWhere((f) => f.name == tableInfo.ck[1]).noneNullType]);

  if (ckCount > 2)
    stringReplaced.add(["__FIELD_TYPE_CK3__", fields.firstWhere((f) => f.name == tableInfo.ck[2]).noneNullType]);

  String result = template;

  for (List<String> sr in stringReplaced) {
    var raw = sr[0];
    var replaced = sr[1];

    result = result.replaceAll(raw, replaced);
  }

  var getName = (FieldElement f) {
    var col = tableInfo.colFields[f.name];
    return col?.name ?? f.name;
  };

  List fieldReplaced = [
    ["__FIELD_TYPE__", (FieldElement f) => f.noneNullType],

    ['PK_VAL__', getName],
    ['PK_NO_CK_VAL__', getName],
    ['CK_VAL__', getName],
    ['NK_VAL__', getName],

    ["__COL_TYPE__", (FieldElement f) => tableInfo.colFields[f.name]!.finalType],
    ['"__COL_TYPE_AND_DEF__"', (FieldElement f) {
      var col = tableInfo.columns[f.name]!;
      String str = '"${col.type}"';

      str += ', field: "${col.field}"';
      str += ', fieldType: "${col.fieldType}"';
      str += ', finalType: "${col.finalType}"';

      if (col.nullable != SqlColumnDef.DEFAULT_NULLABLE)
        str += ', nullable: ${col.nullable.toString()}';

      if (col.oldName != null)
        str += ', oldName: "${col.oldName}"';

      if (col.defaultValue != null)
        str += ', defaultValue: "${col.defaultValue}"';

      if (col.transformer != null && col.transformer != SqlTransformer.raw) {
        str += ', transformer: ${col.transformer.toString()}';
      }

      if (col.lazyRestore != null)
        str += ', lazyRestore: ${col.lazyRestore}';

      if (col.transformer == SqlTransformer.sqlSerializable) {
        str += ', transfer: SqlSerializer<${f.noneNullType}, ${col.finalType}>(fromSave: (key, col, { bool fromJson = false, }) => fromJson ? ${f.noneNullType}.instance().fromJson(col) : ${f.noneNullType}.instance().fromSave(col))';
      }

      return str;
    }],
  ];

  List<String> lines = result.split(RegExp("\\n"));

  var fieldsMap = {};
  fields.forEach((f) => fieldsMap[f.name] = f);

  var linesMapped = lines.map((line) {
    if (line.indexOf("K_VAL__") < 0)
      return line;

    List<String> fieldList;

    if (line.contains("PK_VAL__")) fieldList = tableInfo.pk;
    else if (line.contains("PK_NO_CK_VAL__")) fieldList = tableInfo.pkNoCk;
    else if (line.contains("CK_VAL__")) fieldList = tableInfo.ck;
    else if (line.contains("NK_VAL__")) fieldList = tableInfo.nk;
    else
      return line;

    var multiLine = fieldList.map((fieldName) {
      FieldElement field = fieldsMap[fieldName];
      if (field == null) {
        return "// not get field for fieldName: $fieldName";
      }

      var newLine = "$line";
      for (var fr in fieldReplaced) {
        String anchor = fr[0];
        dynamic trans = fr[1];
        var transValue = trans(field);

        newLine = newLine.replaceAll(anchor, transValue);
      }

      // print("newLine: $newLine");
      return newLine;
    });

    // print("multiLine: $multiLine");
    return multiLine.join('\n');
  });

  // print("linesMapped: $linesMapped");
  result = linesMapped.join("\n");

  if (result.indexOf("__") >= 0) {
    result = "CHECK ERROR: Generated sql still exist invalid __, should be processed.\n$result";
  }

  if (ckCount == 1) {

  }

  return result;
}

String genOrmClass(ClassElement element, ConstantReader annotation, BuildStep buildStep) {
  var tpl = new File('lib/util/storage/generator/tpl.dart').readAsStringSync();

  var clazz = tpl.between("// GENERATION START", "// GENERATION END");

  var table1N = tpl.between("// GENERATION TABLE 1N START", "// GENERATION TABLE 1N END");
  var tableNN = tpl.between("// GENERATION TABLE NN START", "// GENERATION TABLE NN END");
  var tableNNN = tpl.between("// GENERATION TABLE NNN START", "// GENERATION TABLE NNN END");

  var tableInfo = parseTableInfo(element, annotation, buildStep);

  bool existLazyColumns = tableInfo.existLazy;
  if (!existLazyColumns) {
    clazz = clazz.removeBetween('//#if lazyColumns', '//#endif lazyColumns');
  } else {
    clazz = clazz.replaceAll('//#if lazyColumns', '');
    clazz = clazz.replaceAll('//#endif lazyColumns', '');
  }

  var className = element.name;
  var result = <String> [
    generate(className, tableInfo, clazz),
  ];

  if (tableInfo.ck.length == 1) {
    result.add(generate(className, tableInfo, table1N));
  } else if (tableInfo.ck.length == 2) {
    result.add(generate(className, tableInfo, tableNN));
  } else if (tableInfo.ck.length == 3) {
    result.add(generate(className, tableInfo, tableNNN));
  } else {
    result.add('CHECK ERROR: ckCount should be [1, 3], not: ${tableInfo.ck.length}');
  }

  return result.join('\n');
}

class SqlTableGenerator extends CommonGeneratorForAnnotation<SqlTableDef> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    print("generating for: $element");
    try {
      if (element is ClassElement)
        return genOrmClass(element, annotation, buildStep);
    } catch (e, stacktrace) {
      var str = "error: ${errorMsg(e, stacktrace)}";

      print(str);
      return "CHECK_ERROR: \n/**\n$str\n*/";
    }
  }

  @override
  String getFile() {
    throw RuntimeException("should never run here.");
  }
}

Builder sqlTableBuilder(BuilderOptions options) =>
    PartBuilder([SqlTableGenerator()], ".orm.g.dart");