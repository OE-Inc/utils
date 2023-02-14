

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

// ignore_for_file: non_constant_identifier_names, camel_case_extensions, camel_case_types, unused_element, unused_field

import 'package:utils/util/json.dart';

import 'common.dart';

abstract class CLASS_NAME__ extends Jsonable<CLASS_NAME__> {
  //

  var FIELD_NAME__;
}

// GENERATION START

extension CLASS_NAME__JsonExt on CLASS_NAME__ {

  @override
  Map<String, dynamic> toJson() {
    return {
      if (this.FIELD_NAME__ != null) "FIELD_NAME__": this.FIELD_NAME__,
    };
  }

  @override
  CLASS_NAME__ fromJson(Map<String, dynamic> map) {
    this.FIELD_NAME__ = map["FIELD_NAME__"] ?? this.FIELD_NAME__;
    return this;
  }
}

// GENERATION END

