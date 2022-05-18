import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:utils/util/simple_interface.dart';
import 'package:utils/util/utils.dart';
import 'package:source_gen/source_gen.dart';

export 'package:analyzer/dart/constant/value.dart';
export 'package:analyzer/dart/element/element.dart';
export 'package:analyzer/dart/element/type.dart';
export 'package:build/build.dart';
export 'package:source_gen/source_gen.dart';


extension DartObjectExt on DartObject {

  dynamic constValue() {
    if (this == null)
      return null;

    String type = toString();

    switch (type.substring(0, type.indexOf(' '))) {
      case 'int': return toIntValue();
      case 'String': return toStringValue();
      case 'bool': return toBoolValue();
      case 'double': return toDoubleValue();

      default: throw IllegalArgumentException("Only support primitive const value, not: $this");
    }
  }

  String? getFieldStringValue(String name) {
    return getField(name)?.toStringValue();
  }

}

const _debugLog = true;
extension FieldExt on FieldElement {

  String get noneNullType => type.getDisplayString(withNullability: false);

  DartType? returnTypeOfMethod(String method) {
    // print("returnTypeOfMethod checking f: $this, type.element: ${this.type.element}");
    ClassElement ce = this.type.element as ClassElement;

    MethodElement? toSave;

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

    // if (_debug) print("toSave element: $toSave, return type: ${toSave?.type.returnType}");

    if (toSave == null)
      return null;

    return toSave.type.returnType;
  }


  ElementAnnotation? firstMeta(Type type) {
    ElementAnnotation? first;
    var checkMeta = (m) {
      DartObject ccv = m.computeConstantValue();
      // print('getFirstMeta: $type, meta: $m, name: ${this.name}, type: ${ccv.type}, elem: ${ccv.type.element}, is: ${ccv.type.isAssignableTypeOf(type)}');

      return ccv.type?.isAssignableTypeOf(type) == true;
    };

    first = this.metadata.firstWhereNullable(checkMeta)
        ?? this.getter?.metadata.firstWhereNullable(checkMeta)
        ?? this.setter?.metadata.firstWhereNullable(checkMeta);

    // print('name: $name, firstMeta: $type, first: $first, metas: ${this.metadata}, getterMeta: ${this.getter?.metadata}, setterMeta: ${this.setter?.metadata}');

    return first;
  }

  dynamic constValue() {
    return computeConstantValue()?.constValue();
  }
}

extension ElementAnnotationExt on ElementAnnotation {

  dynamic fieldValue(String field) => computeConstantValue()?.getField(field)?.constValue();
  
}

extension ConstantReaderExt on ConstantReader {
  dynamic value() {
    if (this == null)
      return null;

    if (isBool) return boolValue;
    else if (isDouble) return doubleValue;
    else if (isInt) return intValue;
    else if (isString) return stringValue;
    else if (isMap) return mapValue;
    else if (isType) return typeValue;
    else if (isList) return listValue;
    else if (isNull) return null;
    else throw IllegalArgumentException('ConstantReader cannot read value: $this');
  }

  dynamic fieldValue(String field) => read(field).value();
}

extension DartTypeExt on DartType {

  bool isType(Type type) {
    return TypeChecker.fromRuntime(type).isExactlyType(this);
  }

  bool isSuperTypeOf(Type type) {
    return TypeChecker.fromRuntime(type).isSuperTypeOf(this);
  }

  bool isAssignableTypeOf(Type type) {
    // print("isAssignableTypeOf: $type, dartType: $this.");
    return TypeChecker.fromRuntime(type).isAssignableFromType(this);
  }

}


class SimpleClassInfo {
  ClassElement clazz;
  ConstantReader annotation;
  BuildStep buildStep;

  late String className;
  late String typeName;

  late DartType  type;

  late List<String> fields;
  late List<FieldElement> fieldElements;
  late List<String> staticFields;
  late List<FieldElement> staticFieldElements;

  // List<String> methods;
  // List<String> staticMethods;

  Map<String, FieldElement> fieldMap = {};
  Map<String, FieldElement> staticFieldMap = {};

  SimpleClassInfo(this.clazz, this.annotation, this.buildStep) {
    className = clazz.name;
    type = clazz.thisType;
    typeName = type.getDisplayString(withNullability: false);

    /*
    print('\nname: ${clazz.name}\n'
        'raw fields: ${clazz.fields.map((f) => f.name)}\n'
        'raw methods: ${clazz.methods.map((f) => f.name)}\n');

    print('\nfirst is statis: ${clazz.fields[0].isStatic}/${clazz.fields[0].constantValue}/${clazz.fields[0].initializer}/${clazz.fields[0].computeConstantValue().toIntValue()}\n'
    'where static: ${clazz.fields.where((f) => f.isStatic)}\n'
    'where static list: ${clazz.fields.where((f) => f.isStatic).toList()}\n');
    // */

    fieldElements = clazz.fields.where((f) => !f.isStatic && f.getter!.isSynthetic).toList();
    fields = fieldElements.map((f) => f.name).toList();
    fieldElements.forEach((f) => fieldMap[f.name] = f);

    staticFieldElements = clazz.fields.where((f) => f.isStatic && f.getter!.isSynthetic).toList();
    staticFields = staticFieldElements.map((f) => f.name).toList();
    staticFieldElements.forEach((f) => staticFieldMap[f.name] = f);

    if (_debugLog)
      print('\nname: ${clazz.name}\n'
          'fields: $fields/$fieldElements\n'
          'static fields: $staticFields/$staticFieldElements\n');
  }
}


abstract class LineReplacer {
  String replace(String line);
}

class FieldReplacer extends LineReplacer {
  SimpleClassInfo clazz;
  bool allowDuplicateStaticValue;
  bool allowNullStaticValue;

  // [ ['string', replacer], ..., ]
  late List fieldReplaced;
  Map<dynamic, String>  checkDup = { };

  FieldReplacer(this.clazz, { this.allowDuplicateStaticValue = true, this.allowNullStaticValue = true, }) {
    fieldReplaced = [
      ['STATIC_FIELD_NAME__', (String line, FieldElement f) => f.name],
      ["STATIC_FIELD_TYPE__", (String line, FieldElement f) => f.type.getDisplayString(withNullability: false)],
      ["STATIC_FIELD_VALUE__", (String line, FieldElement f) {
        var v = f.constValue();
        if (v == null && !allowNullStaticValue) {
          throw IllegalArgumentException('${clazz.className}.${f.name} == null, class: $clazz.');
        }

        if (v != null && !allowDuplicateStaticValue) {
          var existed = checkDup[v];
          if (existed != null && existed != f.name)
            throw IllegalArgumentException('${clazz.className}.${f.name} value is duplicated: $v, class: $clazz.');

          checkDup[v] = f.name;
        }

        return v is String ? '"$v"' : '$v';
      }],

      ['FIELD_NAME__', (String line, FieldElement f) => f.name],
      ["FIELD_TYPE__", (String line, FieldElement f) => f.type.getDisplayString(withNullability: false)],
    ];
  }

  @override
  String replace(String line) {
    if (line.indexOf("FIELD_NAME__") < 0) {

      return line;
    }

    List<String> fieldList;
    Map<String, FieldElement> fieldsMap;

    if (line.contains("STATIC_FIELD_NAME__")) {
      fieldList = clazz.staticFields;
      fieldsMap = clazz.staticFieldMap;
    } else if (line.contains("FIELD_NAME__")) {
      fieldList = clazz.fields;
      fieldsMap = clazz.fieldMap;
    } else
      return line;

    var multiLine = fieldList.map((fieldName) {
      FieldElement field = fieldsMap[fieldName]!;
      if (field == null) {
        return "// not get field for fieldName: $fieldName";
      }

      if (field.hasDoNotStore) {
        return "// DoNotStore for fieldName: $fieldName";
      }

      var newLine = "$line";
      for (var fr in fieldReplaced) {
        String anchor = fr[0];
        dynamic trans = fr[1];
        var transValue = trans(newLine, field);

        newLine = newLine.replaceAll(anchor, transValue);
      }

      return newLine;
    });

    return multiLine.join('\n');
  }
}

abstract class CommonGeneratorForAnnotation<TYPE> extends GeneratorForAnnotation<TYPE> {

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    return [
      "\n// ignore_for_file: unnecessary_this \n",

      await super.generate(library, buildStep),
    ].join('\n');
  }


  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    try {
      if (element is ClassElement)
        return await defaultGenerator(element, annotation, buildStep);
    } catch (e, stacktrace) {
      var str = "error: ${errorMsg(e, stacktrace)}";

      print(str);
      return "CHECK_ERROR: \n/**\n$str\n*/";
    }
  }

  /// all are function names that may conflict with field name when in extension.
  Set get excludedFields => { 'utc', 'delay', 'repeat', 'concat' };

  String preGenerate(SimpleClassInfo clazz, String template) { return template; }
  String postGenerate(SimpleClassInfo clazz, String template) { return template; }

  List<List<String>> replacedList(SimpleClassInfo clazz) {
    return [
      ["CLASS_NAME__", clazz.className],
    ];
  }

  String doSimpleReplace(SimpleClassInfo clazz, String template) {
    List<List<String>> stringReplaced = replacedList(clazz);
    if (_debugLog) print('stringReplaced: $stringReplaced');

    for (List<String> sr in stringReplaced) {
      var raw = sr[0];
      var replaced = sr[1];

      template = template.replaceAll(raw, replaced);
    }

    return template;
  }


  List<Callable2<SimpleClassInfo, String, String>> getFullReplacers(SimpleClassInfo clazz, String result) {
    return [];
  }

  String doFullReplace(SimpleClassInfo clazz, String template) {
    var fullReplacers = getFullReplacers(clazz, template);
    if (_debugLog) print('fullReplacers: $fullReplacers');

    for (var replacer in fullReplacers) {
      template = replacer(clazz, template);
    }

    return template;
  }

  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String template) {
    return FieldReplacer(clazz);
  }

  List<LineReplacer> getLineReplacers(SimpleClassInfo clazz, String template) {
    return [getFieldReplacer(clazz, template)];
  }

  String doLineReplace(SimpleClassInfo clazz, String template) {
    List<String> lines = template.split(RegExp("\\n"));
    List<LineReplacer> replacers = getLineReplacers(clazz, template);

    if (_debugLog) print('lineReplacers: $replacers');

    var linesMapped = lines.map((line) {
      for (var r in replacers) {
        line = r.replace(line);
      }

      return line;
    });

    return linesMapped.join("\n");
  }

  String commonGenerate(SimpleClassInfo clazz, String template) {
    template = doSimpleReplace(clazz, template);
    template = doFullReplace(clazz, template);
    template = doLineReplace(clazz, template);

    return template;
  }

  Future<List<String>> getTemplates(BuildStep buildStep) async {
    var file = getFile();
    if (_debugLog) print('template file: $file');

    var assetId = AssetId("ripp_link_core", file);

    var tpl = await buildStep.canRead(assetId)
        ? await buildStep.readAsString(assetId)
        : new File(file).readAsStringSync();

    return [tpl.between("// GENERATION START", "// GENERATION END")];
  }

  /// eg: 'lib/util/storage/generator/tpl.dart'
  /// eg: 'lib/util/source_gen/template/enum.dart'
  String getFile();

  Future<dynamic> defaultGenerator(Element element, ConstantReader annotation, BuildStep buildStep) async {
    var templates = await getTemplates(buildStep);
    var result = <String> [];

    if (_debugLog) print('templates: \n$templates');

    var clazz = SimpleClassInfo(element as ClassElement, annotation, buildStep);

    for (var tpl in templates) {
      var r = commonGenerate(clazz, tpl);

      result.add(r);

      if (r.indexOf("__") >= 0) {
        result.add("CHECK ERROR:\nGenerated sql still exist invalid __, should be processed.");
      }
    }

    return result.join('\n');
  }
}