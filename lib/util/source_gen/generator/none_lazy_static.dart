
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import '../annotation/none_lazy_static.dart';
import 'source_gen_ext.dart';

class NoneLazyStaticFieldReplacer extends FieldReplacer {

  NoneLazyStaticFieldReplacer(SimpleClassInfo clazz) : super(clazz) {
    fieldReplaced.insert(0, ['STATIC_FIELD_NAME__', (String line, FieldElement f) => f.name]);
  }

}

class NoneLazyStaticClassGenerator extends CommonGeneratorForAnnotation<NoneLazyStaticClass> {

  @override
  FieldReplacer getFieldReplacer(SimpleClassInfo clazz, String template) {
    return NoneLazyStaticFieldReplacer(clazz);
  }

  @override
  List<List<String>> replacedList(SimpleClassInfo clazz) {
    return super.replacedList(clazz);
  }

  @override
  String getFile() {
    return 'lib/util/source_gen/template/none_lazy_static.dart';
  }
}

Builder noneStaticClassBuilder(BuilderOptions options) =>
    PartBuilder([NoneLazyStaticClassGenerator()], ".init.g.dart");
