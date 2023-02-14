
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'package:utils/util/storage/index.dart';

class MinTimeExecutor {
  int minTime;

  MinTimeExecutor(this.minTime);

  Future<T> wait<T>(Future<T> pending, { int? minTime }) async {
    var s = utc();

    var r = await pending;
    var using = utc() - s;

    minTime ??= this.minTime;
    if (using < minTime)
      await delay(minTime - using);

    return r;
  }

  Future<T> execute<T>(Future<T> Function() run, { int? minTime }) {
    return wait(run(), minTime: minTime);
  }
}