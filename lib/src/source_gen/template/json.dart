

import 'package:utils/src/json.dart';

import 'common.dart';

abstract class CLASS_NAME__ extends Jsonable<CLASS_NAME__> {
  //
}

// GENERATION START

extension CLASS_NAME__Ext on CLASS_NAME__ {

  @override
  Map<String, dynamic> toJson() {
    return {
      "FIELD_NAME__": FIELD_NAME__,
    };
  }

  @override
  CLASS_NAME__ fromJson(Map<String, dynamic> map) {
    FIELD_NAME__ = map["FIELD_NAME__"] ?? FIELD_NAME__;
    return this;
  }
}

// GENERATION END

