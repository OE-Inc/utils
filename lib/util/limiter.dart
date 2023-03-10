

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Rights Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Rights Reserved.
 */

import 'package:utils/util/utils.dart';

import 'log.dart';

const _TAG = "Limiter";

class QpsLimiter {

  double qps;
  int remains;
  int maxRemains;

  int lastFeedUtc;

  QpsLimiter(this.qps, this.maxRemains, { this.remains = 0, this.lastFeedUtc = 0, });

  bool get(int count) {
    if (remains < count) {
      feed();
    }

    if (remains < count)
      return false;

    remains -= count;
    return true;
  }

  void feed() {
    var now = utc();
    var interval = (now - lastFeedUtc) / 1000.0;

    var feeds = (interval * qps).floor();
    if (feeds < 1)
      return;

    lastFeedUtc += (qps * feeds).round();

    if (feeds > maxRemains - remains) {
      lastFeedUtc = now;
      feeds = maxRemains - remains;
    }

    remains += feeds;
    Log.i(_TAG, () => 'feed $feeds, using period: ${feeds / qps} S.');
  }

}