

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';
import 'dart:math';

import 'package:utils/util/utils.dart';

import 'log.dart';

const String _TAG = "TimeLivingAction";

typedef TimeAction = void Function(TimeLivingAction act, TimeLivingInvokeType type, int beatLiving);

enum TimeLivingInvokeType {
  start,
  interval,
  end,
}

class TimeLivingAction {

  int     startUtc = 0;
  int     endUtc = 0;
  int     interval = -1;

  TimeAction? startAction, endAction, intervalAction;
  Timer?      loopTimer;

  bool get  isDead => endUtc <= utc();
  int get   remains => endUtc - utc() > 0 ? endUtc - utc() : 0;

  int get   beatLiving => isDead ? 0 : min(interval, endUtc - utc());

  TimeLivingAction(this.endUtc, { this.interval = 0, this.startAction, this.endAction, this.intervalAction, }) {
    this.intervalAction = this.intervalAction ?? this.startAction;
    this.startAction = this.startAction;

    updateTimer();
  }

  setEndUtc(int endUtc, bool more) {
    if (more && endUtc < this.endUtc) {
      return;
    }

    this.endUtc = endUtc;
    Log.v(_TAG, () => "time living action will die when: $endUtc [${DateTime.fromMillisecondsSinceEpoch(endUtc).toIso8601String()}]");
    updateTimer();
  }

  die() {
    Log.v(_TAG, () => "time living action set die.");
    setEndUtc(utc(), false);
  }

  liveMore(int moreTimeMs, [ bool fromNow = true ]) {
    Log.v(_TAG, () => "time living action set more living: $moreTimeMs ms, fromNow: $fromNow");
    setEndUtc((fromNow ? utc() : endUtc) + moreTimeMs, true);
  }

  liveTo(int toUtc) {
    Log.v(_TAG, () => "time living action set more living to: $toUtc ms");
    setEndUtc(toUtc, false);
  }

  int oldEndUtc = 0, oldInterval = 0;
  updateTimer() {
    if (oldEndUtc == endUtc && oldInterval == interval)
      return;

    oldEndUtc = endUtc;
    oldInterval = interval;

    if (isDead) {
      Log.d(_TAG, () => "time living action already died.");
      endAction?.call(this, TimeLivingInvokeType.end, 0);
      loopTimer?.cancel();
      loopTimer = null;
      return;
    }

    bool calledStart = false;
    if (startUtc == 0 || oldEndUtc <= utc()) {
      startUtc = utc();

      Log.d(_TAG, () => "time living action start.");
      startAction?.call(this, TimeLivingInvokeType.start, interval);
      calledStart = true;
    }

    if (endAction != null) {
      int dieUtc = endUtc;
      Log.d(_TAG, () => "set dieUtc: $dieUtc [${DateTime.fromMillisecondsSinceEpoch(dieUtc).toIso8601String()}].");

      Timer(Duration(milliseconds: remains), () {
        if (dieUtc == endUtc) {
          Log.d(_TAG, () => "time living action died.");
          endAction?.call(this, TimeLivingInvokeType.end, 0);
        }
      });
    }

    if (oldInterval == interval && loopTimer != null)
      return;

    loopTimer?.cancel();

    if (interval <= 0)
      return;

    if (intervalAction == null)
      return;

    Log.d(_TAG, () => "set interval timer: ${Duration(milliseconds: interval).toString()}.");
    loopTimer = Timer.periodic(Duration(milliseconds: interval), (timer) {
      if (isDead) {
        timer.cancel();
        if (timer == loopTimer)
          loopTimer = null;
        return;
      }

      Log.d(_TAG, () => "interval timer beating.");
      intervalAction?.call(this, TimeLivingInvokeType.interval, interval);
    });

    if (calledStart == false || intervalAction != startAction)
      intervalAction?.call(this, TimeLivingInvokeType.interval, interval);
  }

  reset() {
    startUtc = 0;
    setEndUtc(0, false);
  }

  @override
  String toString() {
    return "TimerLivingAction: { startUtc: $startUtc, endUtc: $endUtc [${DateTime.fromMillisecondsSinceEpoch(endUtc).toIso8601String()}], interval: ${Duration(milliseconds: interval).toString()}, startAction: $startAction, endAction: $endAction, intervalAction: $intervalAction, }";
  }

}