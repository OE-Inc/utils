

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

// ignore_for_file: non_constant_identifier_names, camel_case_extensions, camel_case_types

import 'package:utils/util/json.dart';

import 'common.dart';

class CLASS_NAME__ {
  //

  late FIELD_TYPE__ FIELD_NAME__;
  CLASS_NAME__.instance();
}

// GENERATION START

extension CLASS_NAME__CloneExt on CLASS_NAME__ {

  CLASS_NAME__ copyWith({
    FIELD_TYPE__? FIELD_NAME__,
  }) {
    CLASS_NAME__ copy = CLASS_NAME__.instance();
    copy.FIELD_NAME__ = FIELD_NAME__ ?? this.FIELD_NAME__;

    return copy;
  }

  CLASS_NAME__ assignWith({
    FIELD_TYPE__? FIELD_NAME__,
  }) {
    CLASS_NAME__ assign = this;
    assign.FIELD_NAME__ = FIELD_NAME__ ?? this.FIELD_NAME__;

    return this;
  }

  /// replace null field of this, from o.
  CLASS_NAME__ assignWithObj(CLASS_NAME__? a) {
    if (a == null) return this;
    return this.assignWith(
      FIELD_NAME__: a.FIELD_NAME__,
    );
  }

  /// replace null field of this, from o.
  CLASS_NAME__ mergeWith(CLASS_NAME__ m) {
    return m.copyWith(
      FIELD_NAME__: this.FIELD_NAME__,
    );
  }

}

// GENERATION END

