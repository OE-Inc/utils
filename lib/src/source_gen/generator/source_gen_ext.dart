import 'dart:io';
// import 'dart:mirrors'; // NOTE: this file should never imported by app, because it will import dart:mirrors from dependencies, .

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:utils/src/error.dart';
import 'package:utils/src/simple_interface.dart';
import 'package:source_gen/source_gen.dart';

export 'package:analyzer/dart/constant/value.dart';
export 'package:analyzer/dart/element/element.dart';
export 'package:analyzer/dart/element/type.dart';
export 'package:build/build.dart';
export 'package:source_gen/source_gen.dart';

extension StringExt on String {
  String between(String start, String end) {
    var genStart = indexOf(start);
    var genEnd = indexOf(end);

    return substring(genStart, genEnd);
  }
}

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
}

const _debugLog = true;
extension FieldExt on FieldElement {

  DartType returnTypeOfMethod(String method) {
    ClassElement ce = this.type.element as ClassElement;
    var toSave = ce.methods.where((f) => f.name == method).first;

    return toSave.type.returnType;
  }


  ElementAnnotation firstMeta(Type type) {
    try {
      return this.metadata.firstWhere((m) {
        DartObject ccv = m.computeConstantValue();
        return ccv.type.isAssignableTypeOf(type);
      });
    } catch (e) {
    }

    return null;
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

  dynamic fieldValue(String field) => read(field)?.value();
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

  String className;
  String typeName;

  DartType  type;

  List<String> fields;
  List<FieldElement> fieldElements;
  List<String> staticFields;
  List<FieldElement> staticFieldElements;

  // List<String> methods;
  // List<String> staticMethods;

  Map<String, FieldElement> fieldMap = {};
  Map<String, FieldElement> staticFieldMap = {};

  SimpleClassInfo(this.clazz, this.annotation, this.buildStep) {
    className = clazz.name;
    type = clazz.thisType;
    typeName = type.name;

    /*
    print('\nname: ${clazz.name}\n'
        'raw fields: ${clazz.fields.map((f) => f.name)}\n'
        'raw methods: ${clazz.methods.map((f) => f.name)}\n');

    print('\nfirst is statis: ${clazz.fields[0].isStatic}/${clazz.fields[0].constantValue}/${clazz.fields[0].initializer}/${clazz.fields[0].computeConstantValue().toIntValue()}\n'
    'where static: ${clazz.fields.where((f) => f.isStatic)}\n'
    'where static list: ${clazz.fields.where((f) => f.isStatic).toList()}\n');
    // */

    fieldElements = clazz.fields.where((f) => !f.isStatic && f.getter.isSynthetic).toList();
    fields = fieldElements.map((f) => f.name).toList();
    fieldElements.forEach((f) => fieldMap[f.name] = f);

    staticFieldElements = clazz.fields.where((f) => f.isStatic && f.getter.isSynthetic).toList();
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
  List fieldReplaced;
  Map  checkDup = { };

  FieldReplacer(this.clazz, { this.allowDuplicateStaticValue = true, this.allowNullStaticValue = true, }) {
    fieldReplaced = [
      ['STATIC_FIELD_NAME__', (FieldElement f) => f.name],
      ["STATIC_FIELD_TYPE__", (FieldElement f) => f.type.name],
      ["STATIC_FIELD_VALUE__", (FieldElement f) {
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

      ['FIELD_NAME__', (FieldElement f) => f.name],
      ["FIELD_TYPE__", (FieldElement f) => f.type.name],
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

      return newLine;
    });

    return multiLine.join('\n');
  }
}

abstract class CommonGeneratorForAnnotation<TYPE> extends GeneratorForAnnotation<TYPE> {
  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    try {
      if (element is ClassElement)
        return defaultGenerator(element, annotation, buildStep);
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

  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String tempalte) {
    return FieldReplacer(clazz);
  }

  List<LineReplacer> getLineReplacers(SimpleClassInfo clazz, String tempalte) {
    return [getFieldReplacer(clazz, tempalte)];
  }

  String doLineReplace(SimpleClassInfo clazz, String tempalte) {
    List<String> lines = tempalte.split(RegExp("\\n"));
    List<LineReplacer> replacers = getLineReplacers(clazz, tempalte);

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

  List<String> getTemplates() {
    var file = getFile();
    if (_debugLog) print('template file: $file');

    var tpl = new File(file).readAsStringSync();
    return [tpl.between("// GENERATION START", "// GENERATION END")];
  }

  /// eg: 'lib/util/storage/generator/tpl.dart'
  /// eg: 'lib/util/source_gen/template/enum.dart'
  String getFile();

  defaultGenerator(Element element, ConstantReader annotation, BuildStep buildStep) {
    var templates = getTemplates();
    var result = <String> [];

    if (_debugLog) print('templates: \n$templates');

    var clazz = SimpleClassInfo(element, annotation, buildStep);

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