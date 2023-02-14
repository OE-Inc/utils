

/*
 * Copyright (c) 2019-2023 OE Technology (Shenzhen) Co., Ltd. All Right Reserved.
 * Copyright (c) 2019-2023 偶忆科技（深圳）有限公司. All Right Reserved.
 */

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:utils/util/unit.dart';

import 'enum.dart';
import 'log.dart';
import 'qpt.dart';
import 'utils.dart';

const String _TAG = 'PriorityPendingList';

abstract class PriorityPendingItem<ENUM extends EnumInt> {
  ENUM        priority;
  int         createUtc = utc();
  int         endUtc = 0;
  int         timeout;
  Error?      error;
  bool        completed = false;

  List<Completer<void>> waiting = [];

  PriorityPendingItem(this.priority, this.timeout);

  Future<void> start();

  void onComplete(error) {
    if (completed)
      Log.e(_TAG, () => "$runtimeType already completed: $this.", RuntimeException("never complete twice.").thrown());

    completed = true;
    endUtc = utc();
    this.error = error;
    waiting.forEach((w) => error == null ? w.complete(null) : w.completeError(error));
    waiting.clear();
  }

  Future<bool> waitComplete() {
    var c = Completer<bool>();

    if (completed) {
        error != null
            ? c.completeError(error!)
            : c.complete(null);
    } else
      waiting.add(c);

    return c.future;
  }

  bool expired() {
    return duration >= timeout;
  }

  int get duration => (endUtc == 0 ? utc() : endUtc) - createUtc;

  String moreString();

  @override
  String toString() {
    return '$runtimeType { priority: $priority, expired: ${expired()}, duration: ${TimeUnit.periodString(duration)}, ${moreString()}, timeout: $timeout, }';
  }
}

class PriorityPendingList<ENUM extends EnumInt, ITEM extends PriorityPendingItem<ENUM>> {
  @protected
  SplayTreeMap<ENUM, List<ITEM>>  pending = SplayTreeMap();
  @protected
  List<ITEM>                      processing = [];
  int                             startUtc = 0;

  SplayTreeMap<ENUM, int>         maxPrioritySize = SplayTreeMap();
  int                             maxSize = 20;
  bool                            enableQpt = true;
  Qpt                             qpt = Qpt(10 * 1000);
  int                             concurrentSize;
  bool                            _retryGet = false;

  bool Function(ENUM priority)?   priorityAllowed;

  PriorityPendingList({ this.priorityAllowed, this.concurrentSize = 1, });

  int? _size;
  int get size => _size ?? (_size = pending.isEmpty ? 0 : pending.values.fold<int>(0, ((val, item) => val + item.length)));


  @protected
  List<ITEM> getList(ENUM priority) {
    return pending[priority] ?? (pending[priority] = []);
  }

  bool remove(ITEM item, { Error? error, bool callOnRemove = true, }) {
    _size = null;

    bool r = pending[item.priority]?.remove(item) == true;

    if (callOnRemove == true)
      _onRemoved(item, error);
    Timer.run(() => item.onComplete(error));

    return r;
  }

  void _onRemoved(ITEM item, Error? e) {
    try {
      onRemoved(item, e);
    } catch (e) {
      Log.e(_TAG, () => "onRemove occurs error: ", e);
    }
  }

  void onRemoved(ITEM item, Error? e) {
    return;
  }

  /// used to remove conflicted items.
  void removeConflict(ITEM item) {
    return;
  }

  Future<T> push<T extends ITEM>(T item) async {
    var l = getList(item.priority);

    removeConflict(item);

    var maxPrSize = maxPrioritySize[item.priority];
    if (maxPrSize != null) {
      // remove the oldest.
      while (maxPrSize <= l.length) {
        var removed = l.removeAt(0);
        if (removed == null)
          continue;

        // Log.w(_TAG, () => 'removed too many item: $removed.');
        var e = PendingListFullError('priority list full.').thrown();
        _onRemoved(removed, e);
        Timer.run(() => removed.onComplete(e));
      }
    }

    _size = null;
    l.add(item);
    if (enableQpt) qpt.add();

    // Log.d(_TAG, () => "push item: $item. existed: ${pending}");

    if (startUtc <= 0)
      Timer.run(() => startUtc <= 0 ? start() : null);

    checkMaxSize();

    await item.waitComplete();
    return item;
  }

  void checkMaxSize() {
    if (size <= maxSize)
      return;

    var removed = <ITEM>[];

    int removedSize = 2;
    var keys = pending.keys.toList().reversed;

    for (var priority in keys) {
      if (removedSize <= 0)
        break;

      var l = pending[priority]!;
      if (l.length == 0)
        continue;

      var sz = min(l.length, removedSize);
      removedSize -= sz;

      removed.addAll(l.sublist(0, sz));
      l.removeRange(0, sz);
    }

    var e = PendingListFullError('max list full.').thrown();
    for (var r in removed) {
      _onRemoved(r, e);
      Timer.run(() => r.onComplete(e));
    }

    Log.w(_TAG, () => 'removing low priority list: $removed.');
  }

  ITEM? getNext({ bool remove = false, bool log = false, }) {
    ITEM? t;

    for (var priority in pending.keys) {
      var l = pending[priority]!;

      if (l.isEmpty) {
        continue;
      }

      var pa = priorityAllowed;
      if (pa != null && !pa(priority)) {
        if (log) Log.w(_TAG, () => "Priority not allowed: $priority, msg: ${l.firstNullable}");
        continue;
      }

      t = l.removeAt(0);
      _onRemoved(t, null);
      break;
    }

    if (t != null) {
      _size = null;
      // Log.d(_TAG, () => "getNext msg: $t.");
    }

    return t;
  }

  void start() async {
    if (startUtc > 0)
      throw RuntimeException("Should never call start() when already started.");

    var sUtc = startUtc = utc();

    try {
      await _startLoop();

      if (startUtc == sUtc)
        startUtc = 0;
    } catch (e) {
      Log.e(_TAG, () => 'startLoop fail, retry in 2s, error: ', e);

      delay(2000).then((_) => start());
    }
  }

  Future<void> _startLoop() async {
    var sUtc = startUtc;
    while (true) {
      if (size == 0) {
        return;
      }

      if (startUtc != sUtc)
        return;

      await next();
    }
  }

  Future<void> next() async {
    while (true) {
      if (processing.length >= concurrentSize) {
        break;
      }

      if (pending.isEmpty) {
        break;
      }

      doNext().catchError((e) => Log.e(_TAG, () => 'doNext error: ', e));
      await delay(10);
    }

    await delay(50);
  }

  /// returns retry.
  @protected
  Future<void> doNext() async {
    var item = getNext(log: !_retryGet);

    if (item == null) {
      if (!_retryGet) Log.w(_TAG, () => 'get item skipped, wait for next retry.');

      await delay(50);
      _retryGet = true;
      return;
    }
    _retryGet = false;

    // Log.d(_TAG, () => "start item: $item");

    processing.add(item);

    var error;
    try {
      // already timeout...
      if (item.expired()) {
        throw TimeoutError('item already expired.');
      }

      await item.start();
      // Log.d(_TAG, () => "item result success, item: $item");
    } catch (e) {
      // Log.e(_TAG, () => "item result failed, item: $item, error: ", e);
      error = e;
    }

    processing.remove(item);

    Timer.run(() => item.onComplete(error));
  }

  @override
  String toString() {
    return "$runtimeType { qpt: $qpt, processing: ${processing.length}, pending: ${pending.keys.map((k) => "$k: ${pending[k]!.length}")}, }";
  }

}