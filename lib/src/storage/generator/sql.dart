import 'dart:io';
import 'dart:typed_data';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:utils/src/error.dart';
import 'package:utils/src/storage/annotation/sql.dart';
import 'package:utils/src/storage/sql/table_info.dart';
import 'package:utils/src/utils.dart';
import 'package:source_gen/source_gen.dart';

const _debug = false;
extension FieldExt on FieldElement {

  DartType returnTypeOfMethod(String method) {
    print("returnTypeOfMethod checking f: $this, type.element: ${this.type.element}");
    ClassElement ce = this.type.element as ClassElement;

    MethodElement toSave;

    if (ce.methods.any((f) => f.name == method)) {
      toSave = ce.methods.where((f) => f.name == method).first;
    } else {
      for (var s in ce.allSupertypes) {
        if (s.methods.any((f) => f.name == method)) {
          toSave = s.methods.where((f) => f.name == method).first;
          break;
        }
      }
    }

    if (_debug) print("toSave element: $toSave, return type: ${toSave?.type?.returnType}");

    if (toSave == null)
      return null;

    return toSave.type.returnType;
  }


  ElementAnnotation firstMeta(Type type) {
    ElementAnnotation first;
    var checkMeta = (m) {
      DartObject ccv = m.computeConstantValue();
      // print('getFirstMeta: $type, meta: $m, name: ${this.name}, type: ${ccv.type}, elem: ${ccv.type.element}, is: ${ccv.type.isAssignableTypeOf(type)}');

      return ccv.type.isAssignableTypeOf(type);
    };

    first = this.metadata.firstWhere(checkMeta, orElse: () => null)
        ?? this.getter.metadata.firstWhere(checkMeta, orElse: () => null)
        ?? this.setter.metadata.firstWhere(checkMeta, orElse: () => null);

    print('name: $name, firstMeta: $type, first: $first, metas: ${this.metadata}, getterMeta: ${this.getter?.metadata}, setterMeta: ${this.setter?.metadata}');

    return first;
  }


}

extension DartTypeExt on DartType {

  bool isType(Type type) {
    return TypeChecker.fromRuntime(type).isExactlyType(this);
  }

  bool isSuperTypeOf(Type type) {
    return TypeChecker.fromRuntime(type).isSuperTypeOf(this);
  }

  bool isAssignableTypeOf(Type type) {
    if (_debug) print("isAssignableTypeOf: $type, dartType: $this.");
    return TypeChecker.fromRuntime(type).isAssignableFromType(this);
  }

}

class SimpleTableInfo extends SqlTableInfo {
  List<FieldElement>   fields;

  SimpleTableInfo(this.fields, String tableName, List<String> pk, int ckCount, template) : super(tableName, pk, ckCount, template);

  static const excludeFields = ['hashCode', 'runtimeType', 'equals'];

  static SqlTransformer parseTransformerType(SqlTransformer transformer, FieldElement f) {
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

    throw Exception("Should never provide a invalid col/field when parseTransformerType(), field: $f, type: $type");
  }

  static String parseFinalType(SqlColumnDef col, FieldElement f) {
    var type = f.type;

    SqlTransformer transformer = col?.transformer;

    if (transformer != null) {
      switch (transformer) {
        case SqlTransformer.base64:
        case SqlTransformer.json:
        case SqlTransformer.hex:
          return 'String';

        case SqlTransformer.raw:
          break;

        default:
          throw IllegalArgumentException("Not support SqlColumnDef for tranformer: ${col.transformer}.");
          break;
      }
    }

    if (type.isAssignableTypeOf(SqlSerializable)) {
      type = f.returnTypeOfMethod("toSave");
    }

    if (type.isDartCoreInt || f.type.isDartCoreBool) return '$int';
    else if (type.isDartCoreNum) return "$double";
    else if (type.isDartCoreString) return "$String";

    else if (type.isDartCoreList) return "$String";
    else if (type.isDartCoreMap)  return "$String";

    else if (type.isType(Uint8List)) return "$Uint8List";

    return '$type';
  }

  static String parseColType(SqlColumnDef col, FieldElement f) {
    var type = f.type;

    if (col != null) {
      if (col.type != null) {
        return col.type;
      }

      SqlTransformer transformer = col.transformer;

      if (transformer != null) {
        switch (transformer) {
          case SqlTransformer.base64:
          case SqlTransformer.json:
          case SqlTransformer.hex:
            return "TEXT";

          case SqlTransformer.raw:
            break;

          default:
            throw IllegalArgumentException("Not support SqlColumnDef for tranformer: ${col.transformer}.");
            break;
        }
      }
    }

    if (type.isAssignableTypeOf(SqlSerializable)) {
      type = f.returnTypeOfMethod("toSave");
    }

    /// Supported SQLite types of 'sqflite':
    /// INTEGER <=> int
    /// REAL    <=> num
    /// TEXT    <=> String
    /// BLOB    <=> Uint8List

    if (type.isDartCoreInt || f.type.isDartCoreBool) return "INTEGER";
    else if (type.isDartCoreNum) return "REAL";
    else if (type.isDartCoreString) return "TEXT";

    else if (type.isDartCoreList) return "TEXT";
    else if (type.isDartCoreMap)  return "TEXT";

    else if (type.isType(Uint8List)) return "BLOB";

    throw Exception("Should never provide a invalid col/field when parseColType(), col: $col, field: $f, type: $type");
  }

  static SqlTransformer getTransformerEnum(DartObject map, FieldElement f) {
    var val = map.getField('transformer');
    if (val == null || val.isNull) {
      if (f.type.isAssignableTypeOf(SqlSerializable)) {
        return SqlTransformer.sqlSerializable;
      }

      return parseTransformerType(null, f);
    }

    print("SqlColumnDef meta: $map, transformer: ${map.getField('transformer')}/${map.getField('transformer').type}");
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
      if (_debug) print("checking field: ${f.name}/${f.type.name}/${f.type.displayName}, $f, meta: ${f.metadata}");

      if (f.isConst || f.isFinal || f.isStatic) {
        if (!pk.contains(f.name)) {
          continue;
        }
      }

      if (excludeFields.contains(f.name))
        continue;

      if (f.firstMeta(IgnoredColumn) != null)
        continue;

      SqlColumnDef def;
      var sqlDef = f.firstMeta(SqlColumnDef);
      if (sqlDef != null) {
        var map = sqlDef.computeConstantValue();

        def = SqlColumnDef(
          table: map.getField('table').toStringValue(),
          name: map.getField('name').toStringValue(),
          type: map.getField('type').toStringValue(),
          defaultValue: map.getField('defaultValue').toStringValue(),
          nullable: map.getField('nullable').toBoolValue(),
          transformer: getTransformerEnum(map, f),
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
            fieldType: '${f.type}',
            finalType: parseFinalType(def, f),

            transformer: parseTransformerType(null, f)
        );
      } else {
        def = SqlColumnDef(
          table: def.table,
          name: def.name ?? f.name,
          type: def.type ?? type,

          field: f.name,
          fieldType: '${f.type}',
          finalType: parseFinalType(def, f),

          defaultValue: def.defaultValue,
          nullable: def.nullable,
          transformer: def.transformer,
          // transfer: transfer,
        );
      }

      map[def.name] = def;
    }

    return map;
  }

  @override
  fillTemplateKeys(part, bool withPk, bool withCk) {
    throw UnimplementedError();
  }

  @override
  SqlWhereObj getWhere(part, bool withPk, bool withCk, bool withNk, {SqlWhereObj where}) {
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
}


//BuildStep resolver;

/// all are function names that may conflict with field name when in extension.
const Set excludedFields = { 'utc', 'delay', 'repeat', 'concat' };

SimpleTableInfo parseTableInfo(ClassElement element, ConstantReader annotation, BuildStep buildStep) {
  var className = element.name;
  var fields = element.fields;
  element.allSupertypes.forEach((s) {
    if (_debug) print("checking super: coreObj: ${s.isDartCoreObject}, obj: ${s.isObject} $s.");
    if (s.isDartCoreObject || s.isObject)
      return;

    fields.addAll(s.element.fields);
  });

  var tableName = annotation.read('tableName').stringValue;
  var ckCount = annotation.read('collectionKeyCount').intValue;

  var pk = List<String>.from(annotation.read('primaryKeys').listValue.map((s) => s.toStringValue()));

  for (var p in pk) {
    if (!fields.any((f) => p == f.name))
      throw IllegalArgumentException("$className not exist pk: '$p', pks: $pk");
  }

  var tableInfo = SimpleTableInfo(fields, tableName, pk, ckCount, null);
  print('parsed table info: $tableInfo');

  return tableInfo;
}

String generate(String className, SimpleTableInfo tableInfo, String template) {
  var tableName = tableInfo.tableName;
  var ckCount = tableInfo.ck.length;
  var pk = tableInfo.pk;
  var fields = tableInfo.fields;

  List<List<String>> stringReplaced = [
    ["__MODEL_CLASS__", className],
    ["__TABLE_NAME__", tableName],
    ["__PK_LIST__", "${pk.map((p) => "'$p'").toList()}"],
    ["__CK_COUNT__", "$ckCount"],
  ];

  if (ckCount > 0)
    stringReplaced.add(["__FIELD_TYPE_CK1__", fields.firstWhere((f) => f.name == tableInfo.ck[0]).type.name]);

  if (ckCount > 1)
    stringReplaced.add(["__FIELD_TYPE_CK2__", fields.firstWhere((f) => f.name == tableInfo.ck[1]).type.name]);

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
    ["__FIELD_TYPE__", (FieldElement f) => f.type.name],

    ['PK_VAL__', getName],
    ['PK_NO_CK_VAL__', getName],
    ['CK_VAL__', getName],
    ['NK_VAL__', getName],

    ["__COL_TYPE__", (FieldElement f) => tableInfo.colFields[f.name].finalType],
    ['"__COL_TYPE_AND_DEF__"', (FieldElement f) {
      var col = tableInfo.columns[f.name];
      String str = '"${col.type}"';

      str += ', field: "${col.field}"';
      str += ', fieldType: "${col.fieldType}"';
      str += ', finalType: "${col.finalType}"';

      if (col.nullable != SqlColumnDef.DEFAULT_NULLABLE)
        str += ', nullable: ${col.nullable.toString()}';

      if (col.defaultValue != null)
        str += ', defaultValue: "${col.defaultValue}"';

      if (col.transformer != null && col.transformer != SqlTransformer.raw) {
        str += ', transformer: ${col.transformer.toString()}';
      }

      if (col.transformer == SqlTransformer.sqlSerializable) {
        str += ', transfer: SqlSerializer<${f.type}, ${col.finalType}>(fromSave: (key, col, { bool fromJson = false, }) => fromJson ? ${f.type}.instance().fromJson(col) : ${f.type}.instance().fromSave(col))';
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

  var tableInfo = parseTableInfo(element, annotation, buildStep);

  var className = element.name;
  var result = <String> [
    generate(className, tableInfo, clazz),
  ];

  if (tableInfo.ck.length == 1) {
    result.add(generate(className, tableInfo, table1N));
  } else if (tableInfo.ck.length == 2) {
    result.add(generate(className, tableInfo, tableNN));
  } else {
    result.add('CHECK ERROR: ckCount should be 1 or 2, not: ${tableInfo.ck.length}');
  }

  return result.join('\n');
}

class SqlTableGenerator extends GeneratorForAnnotation<SqlTableDef> {
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
}

Builder sqlTableBuilder(BuilderOptions options) =>
    PartBuilder([SqlTableGenerator()], ".orm.g.dart");