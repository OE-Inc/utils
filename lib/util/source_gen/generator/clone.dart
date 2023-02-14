
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:utils/util/enum.dart';
import 'package:utils/util/source_gen/annotation/clone.dart';

import 'source_gen_ext.dart';

class CloneGenerator extends CommonGeneratorForAnnotation<CloneDef> {

  @override
  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String template) {
    var rawTypes = RegExp(r'^(bool|dynamic)$');
    var rawListTypes = RegExp(r'^List\<(String|bool|int|double|num|dynamic)\>$');
    var rawMapTypes = RegExp(r'^Map\<String, ?(String|bool|int|double|num|dynamic)\>$');

    replacer(String raw, String pred, String funcNullable, String funcNoneNull) => (String line, FieldElement f) {
      if (!line.contains(pred))
        return raw;

      var type = f.type.getDisplayString(withNullability: false);
      if (  type == 'UniId'
          || type == 'int'
          || type == 'String'
          || type == 'Color'
          || type == 'double'
          || type == 'Uint8List'
          || f.type.isAssignableTypeOf(Enum)
          || rawTypes.hasMatch(type)
      )
        return raw;

      var isNullable = f.type.getDisplayString(withNullability: true).endsWith('?');
      try {
        if (rawListTypes.hasMatch(type)) {
          return !isNullable ? '[...$raw]' : '($raw == null ? null : [...$raw!])';
        }

        if (rawMapTypes.hasMatch(type)) {
          return !isNullable ? '{...$raw}' : '($raw == null ? null : {...$raw!})';
        }

        if (type.startsWith('List<')) {
          return !isNullable ? '[...$raw]' : '($raw == null ? null : [...$raw!])';
          // return '$raw.map((elem) => elem.copyWith()).toList()';
        }

        if (type.startsWith('Map<')) {
          return !isNullable ? '{...$raw}' : '($raw == null ? null : {...$raw!})';
          // return '$raw.map((kv) => elem.copyWith()).toList()';
        }

      } catch (e) {
        return '("${f.name}" error-clone-processing: /*$type*/)';
      }

      return '$raw${isNullable ? funcNullable : funcNoneNull}';
    };

    var raw = 'this.FIELD_NAME__';
    return FieldReplacer(clazz)
      ..fieldReplaced.insert(0, [raw, replacer(raw, 'copy.', '?.copyWith()', '.copyWith()')])
      ..fieldReplaced.insert(0, [raw, replacer(raw, ',', '?.mergeWith(m.FIELD_NAME__!) ?? m.FIELD_NAME__', '.mergeWith(m.FIELD_NAME__)')])
      ..fieldReplaced.insert(0, [raw, replacer(raw, 'assign.', '', '')])
      ..fieldReplaced.insert(0, ['a.FIELD_NAME__', replacer('a.FIELD_NAME__', 'a.', '?.assignWithObj(a.FIELD_NAME__)', '.assignWithObj(a.FIELD_NAME__)')])
    ;
  }

  @override
  List<List<String>> replacedList(SimpleClassInfo clazz) {
    return super.replacedList(clazz);
  }

  @override
  String getFile() {
    return 'lib/util/source_gen/template/clone.dart';
  }
}

Builder cloneBuilder(BuilderOptions options) =>
    PartBuilder([CloneGenerator()], ".clone.g.dart");
