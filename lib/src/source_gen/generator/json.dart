
import '../annotation/json.dart';
import 'source_gen_ext.dart';

class JsonFieldReplacer extends FieldReplacer {

  JsonFieldReplacer(SimpleClassInfo clazz) : super(clazz) {
    fieldReplaced.insert(0, ['map["FIELD_NAME__"]', (FieldElement f) {
      if (f.type.name == 'UniId')
        return '(map["${f.name}"] != null ? UniId.fromString(map["${f.name}"]) : null)';
      return 'map["${f.name}"]';
    }]);
  }

}

class JsonGenerator extends CommonGeneratorForAnnotation<JsonDef> {

  @override
  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String tempalte) {
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
