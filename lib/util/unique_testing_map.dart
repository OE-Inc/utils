
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:utils/util/utils.dart';

class UniqueTestingMap<KEY> {
  @protected
  Map<KEY, bool> map = {};

  void clear() => map.clear();

  bool check(KEY k) {
    if (map.containsKey(k))
      return false;

    return map[k] = true;
  }
}