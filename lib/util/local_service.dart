
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:math';

import 'package:utils/util/log.dart';
import 'package:utils/util/utils.dart';

mixin CommonLocalServiceMixin {

  // ignore: non_constant_identifier_names
  late final TAG = "$runtimeType";


  int _startUtc = 0;

  bool get started => _startUtc > 0;

  var loopSleepTimeout = 3 * 1000;


  Future<int> startLoop();

  Future<void> start() async {
    var startUtc = _startUtc = uniqueUtc();
    Log.i(TAG, () => "start: $this.");

    while (startUtc == _startUtc) {
      try {
        var nextWakeUtc = await startLoop();

        await delay(max(nextWakeUtc - utc(), loopSleepTimeout));
      } catch (e) {
        Log.e(TAG, () => "start running error, service: $this, error: ", e);
      }

      await delay(loopSleepTimeout);
    }
  }

  void stop() {
    _startUtc = 0;
    Log.i(TAG, () => "stop: $this.");
  }

  void close() {
    stop();
  }

}
