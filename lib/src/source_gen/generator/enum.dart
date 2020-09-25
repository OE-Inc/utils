
import '../../error.dart';
import '../annotation/enum.dart';
import 'source_gen_ext.dart';

class EnumFieldReplacer extends FieldReplacer {

  EnumFieldReplacer(SimpleClassInfo clazz) : super(clazz, allowDuplicateStaticValue: false, allowNullStaticValue: false) {
    fieldReplaced.insert(0, ['ENUM_FIELD_NAME__', (FieldElement f) {
      var m = f.firstMeta(EnumDefField);
      var name = m?.fieldValue('name');
      return name != null ? '"$name"' : 'null';
    }]);
  }

}

class EnumGenerator extends CommonGeneratorForAnnotation<EnumDef> {

  @override
  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String tempalte) {
    return EnumFieldReplacer(clazz);
  }

  @override
  List<List<String>> replacedList(SimpleClassInfo clazz) {
    var name = clazz.typeName;
    if (!name.endsWith('Def') || !name.startsWith("_"))
      throw IllegalArgumentException('Enum class: $name should endsWith "Def" and startsWith "_"');

    var type = clazz.annotation.fieldValue('type');
    print('Enum class: $name, type: $type.');

    if (type != 'int' && type != 'String')
      throw IllegalArgumentException('Enum class: $name only supports int/String.');

    var isNum = type == 'int' || type == 'double' || type == 'num';

    return [
      if (isNum) ['extends Enum<CLASS_NAME__, ENUM_TYPE__>',
        type == 'int' ? 'extends EnumInt<CLASS_NAME__>' : 'extends EnumNum<CLASS_NAME__, ENUM_TYPE__>'
      ],
      ["CLASS_NAME__", clazz.typeName.substring(1, clazz.typeName.length - 3)],
      ["ENUM_TYPE__", type],

      ...(super.replacedList(clazz).where((e) => e[0] != 'CLASS_NAME__').toList())
    ];
  }

  @override
  String getFile() {
    return 'lib/util/source_gen/template/enum.dart';
  }
}

Builder enumBuilder(BuilderOptions options) =>
    PartBuilder([EnumGenerator()], ".enum.g.dart");
