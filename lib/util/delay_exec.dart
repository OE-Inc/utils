
/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

/*
 * Delay executor.
 */
import 'dart:async';

import 'simple_interface.dart';
import 'utils.dart';

class DelayExec {
  int         _nextInvoke = 0, delayStarts = -1, maxDelayOnce = -1;
  int         lastExecUtc = -1;
  int         _delayUnit = 0;
  Runnable    run;

  bool        closed = false;

  ///
  /// If start < 0, then it will not execute automatically.
  /// @param start initial first invoke starts.
  /// @param delay initial first invoke starts delay.
  /// @param delayUnit_ the unit when Delay() is called to delay.
  /// @param maxDelayOnce_ the max time that delays once.
  /// @param run_ the executable when invoked.
  DelayExec(int? delay, int delayUnit, this.run, { int? start, this.maxDelayOnce = -1, }): _delayUnit = delayUnit {
    _nextInvoke = start != null && start < 0 ? -1 : (start ?? utc()) + (delay ?? delayUnit);
    checkInvoke();
  }

  close() {
    closed = true;
  }

  bool  runPushed = false;
  void checkRun() {
    runPushed = false;
    checkInvoke();
  }
  
  void checkInvoke() {
    if (closed)
      return;

    int currMS = utc();

    if (_nextInvoke < 0)
      return;

    if (currMS >= _nextInvoke) {
      lastExecUtc = currMS;
      _nextInvoke = -1;
      delayStarts = -1;
      Timer.run(run);
    } else {
      bool reqRun = false;
      if (maxDelayOnce > 0 && delayStarts > 0 && currMS - delayStarts >= maxDelayOnce) {
        lastExecUtc = currMS;
        delayStarts = currMS;
        reqRun = true;
      }

      if (!runPushed) {
        runPushed = true;
        int delta = _nextInvoke - currMS;
        if (maxDelayOnce > 0 && delayStarts > 0 && _nextInvoke - delayStarts >= maxDelayOnce)
          delta = delayStarts + maxDelayOnce - currMS;

        Timer(Duration(milliseconds: delta + 20), () => checkRun());
      }

      // do run here to avoid exception or timer delays in run().
      if (reqRun) Timer.run(run);
    }
  }

  void startDelay() { if (_nextInvoke <= 0) delayStarts = utc(); }

  void delayMore(int delay) {
    startDelay();
    if (_nextInvoke <= 0) _nextInvoke = utc();
    _nextInvoke += delay;
    checkInvoke();
  }

  void delay([int? delay]) {
    delay ??= _delayUnit;
    
    int newNext = utc() + delay;
    if (newNext > _nextInvoke) {
      startDelay();
      _nextInvoke = newNext;
      checkInvoke();
    }
  }

  void delayDirect(int delay) {
    int newNext = utc() + delay;
    if (newNext > _nextInvoke) {
      delayStarts = -1;
      _nextInvoke = newNext;
      checkInvoke();
    }
  }

  void delayTo(int toUtc) {
    startDelay();
    _nextInvoke = toUtc;
    checkInvoke();
  }

  /// Redo immediately if (currMS - nextInvoke >= delayUnit), and then start all the delay flow.
  /// Another word, if it's inter than delayUnit since last invoke done, we will just re-invoke and then continue standard delay flow.
  void resumeLastInvokeAndDelay() {
    int currMS = utc();
    if (isDone() && currMS - lastExecUtc >= _delayUnit && currMS - _nextInvoke >= _delayUnit) {
      _nextInvoke = currMS;
      checkInvoke();
    } else
      delay();
  }

  bool isDone() {
    return lastExecUtc >= _nextInvoke;
  }

  bool isStarted() { return _nextInvoke > 0; }

  int delayUnit() { return _delayUnit; }

  int lastExec() { return lastExecUtc; }

  int delayStartDelta() { return delayStarts > 0 ? utc() - delayStarts : -1; }

  void invokeNowAndClear() {
    _nextInvoke = utc() - 1;
    checkInvoke();
  }

  /// @return < 0 if no invoke is required, else return UTC of nextInvoke.
  int nextInvoke() { return _nextInvoke; }

  /// Always >= -1.
  /// @return if nextInvoke > 0, return currMS - nextInvoke, else return -1;
  int intervalToNext() { return _nextInvoke < 0 ? -1 : _nextInvoke - utc(); }

  /// Redo in delayUnit later.
  void redo() {
    _nextInvoke = utc() + _delayUnit;
    checkInvoke();
  }
}
