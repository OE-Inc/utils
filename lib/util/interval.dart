
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:math';

import 'package:utils/util/unit.dart';

import 'utils.dart';

class Interval {
  int lastProc = 0,
      miniInterval = 0;

  Interval(int msMiniGap, [ bool fromNow = false ]) {
    if (msMiniGap < 0)
      throw new IllegalArgumentException(" Must init with a msGap >= 0");

    miniInterval = msMiniGap;
    lastProc = utc() - (fromNow ? 0 : miniInterval);
  }

  bool peekNext() {
    return (utc() - lastProc) >= miniInterval;
  }

  bool passedNext() {
    int currMS = utc();
    if (currMS - lastProc >= miniInterval) {
      lastProc = currMS;
      return true;
    }
    return false;
  }

  void updateToNow() {
    lastProc = utc();
  }

  void reset() {
    lastProc = -miniInterval;
  }

  int lastProcPeriod() {
    return utc() - lastProc;
  }

}


typedef IntervalGeneratorCalc = int Function(int pre);

class IntervalGenerator {

  static IntervalGeneratorCalc genExp([double e = 2]) => (pre) => (pre * e).toInt();
  static IntervalGeneratorCalc beat() => (pre) => pre;

  int lastUtc = 0;
  int nextUtc = 0;

  int interval;

  int defaultInterval;
  int minInterval;
  int maxInterval;

  int maxActiveTimes;
  int activeTimes = 1;

  int random;

  IntervalGeneratorCalc calc;

  IntervalGenerator(this.interval, {
    required this.minInterval,
    required this.maxInterval,
    required this.calc,

    this.random = 0,
    this.maxActiveTimes = 1,

    int? defaultInterval,
  }): defaultInterval = defaultInterval ?? minInterval;

  bool get occur => nextUtc <= utc();

  void onInterval() {
    nextUtc = max(lastUtc + nextInterval() + rand.nextInt(random), utc());
    lastUtc = utc();
  }

  int nextInterval() {
    var ni = activeTimes-- > 0
        ? minInterval
        : calc(interval)
    ;

    return min(maxInterval, max(ni, minInterval));
  }

  void active() {
    reset(toActive: true);
  }

  void reset({ bool toActive = false, }) {
    lastUtc = 0;
    interval = toActive ? minInterval : defaultInterval;
    activeTimes = maxActiveTimes;

    onInterval();
  }

  @override
  String toString() {
    return "$runtimeType { active: $activeTimes, lastUtc: ${lastUtc.utcString} => ${nextUtc.utcString}, interval: ${interval.periodString} => ${nextInterval().periodString}, }";
  }

}