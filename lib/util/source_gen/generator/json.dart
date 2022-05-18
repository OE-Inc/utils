
import 'package:utils/util/enum.dart';

import '../annotation/json.dart';
import 'source_gen_ext.dart';

class JsonFieldReplacer extends FieldReplacer {

  JsonFieldReplacer(SimpleClassInfo clazz) : super(clazz) {

    var rawTypes = RegExp(r'^(String|bool|int|double|num|dynamic)$');
    var rawListTypes = RegExp(r'^List\<(String|bool|int|double|num|dynamic)\>$');
    var rawMapTypes = RegExp(r'^Map\<String, ?(String|bool|int|double|num|dynamic)\>$');

    fieldReplaced.insert(0, ['this.FIELD_NAME__,', (String line, FieldElement f) {
      var nullableType = f.type.getDisplayString(withNullability: true);
      var mayNull = nullableType.endsWith('?') || nullableType.endsWith('*');
      var type = mayNull ? nullableType.substring(0, nullableType.length - 1) : nullableType;

      if (rawTypes.hasMatch(type) || f.type.isAssignableTypeOf(Enum) || type.startsWith('List<') || type.startsWith('Map<'))
        return 'this.FIELD_NAME__,';

      return 'this.FIELD_NAME__${mayNull ? '?' : ''}.toJson(),';
    }]);

    fieldReplaced.insert(0, ['map["FIELD_NAME__"]', (String line, FieldElement f) {
      var type = f.type.getDisplayString(withNullability: false);
      if (type == 'UniId')
        return '(map["${f.name}"] != null ? UniId.fromString(map["${f.name}"]) : null)';

      if (type == 'int')
        return 'map["${f.name}"]?.toInt()';

      if (type == 'double')
        return 'map["${f.name}"]?.toDouble()';

      if (type == 'String')
        return 'map["${f.name}"]?.toString()';

      if (type == 'Uint8List')
        return '(map["${f.name}"] == null ? null : Uint8List.fromList((map["${f.name}"] as List).cast<int>()))';

      if (rawTypes.hasMatch(type))
        return 'map["${f.name}"]';

      try {
        if (rawListTypes.hasMatch(type)) {
          var listType = type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
          return '(map["${f.name}"] == null ? null : (map["${f.name}"] as List).cast<$listType>()/*$type*/)';
        }

        if (rawMapTypes.hasMatch(type)) {
          var valueType = type.substring(type.indexOf(',') + 1, type.lastIndexOf('>')).trim();
          return '(map["${f.name}"] == null ? null : (map["${f.name}"] as Map).cast<String, $valueType>()/*$type*/)';
        }

        if (f.type.isAssignableTypeOf(Enum)) {
          return '(map["${f.name}"] != null ? ${type}.fromJsonVal(map["${f.name}"]) : null)';
        }

        if (type.startsWith('List<')) {
          var listType = type.substring(type.indexOf('<') + 1, type.lastIndexOf('>'));
          return '(map["${f.name}"] == null ? null : (map["${f.name}"] as Iterable).map<$listType>((v) => (${listType}.instance().fromJson(v))).toList()/*$type*/)';
        }

        if (type.startsWith('Map<')) {
          var valueType = type.substring(type.indexOf(',') + 1, type.lastIndexOf('>')).trim();
          return '(map["${f.name}"] == null ? null : (map["${f.name}"] as Map).map((k, v) => MapEntry<String, $valueType>(k as String, (${valueType}.instance().fromJson(v))))/*$type*/)';
        }

      } catch (e) {
        return '(map["${f.name}"] error-json-processing: /*$type*/)';
      }

      return '(map["${f.name}"] != null ? (${type}.instance().fromJson(map["${f.name}"])) : null /*$type*/)';

      // return 'map["${f.name}"]';
    }]);

  }

}

class JsonGenerator extends CommonGeneratorForAnnotation<JsonDef> {

  @override
  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String template) {
    return JsonFieldReplacer(clazz);
  }

  @override
  List<List<String>> replacedList(SimpleClassInfo clazz) {
    return super.replacedList(clazz);
  }

  @override
  String getFile() {
    return 'lib/util/source_gen/template/json.dart';
  }
}

Builder jsonBuilder(BuilderOptions options) =>
    PartBuilder([JsonGenerator()], ".json.g.dart");
