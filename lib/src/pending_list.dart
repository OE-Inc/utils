

import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:utils/src/unit.dart';

import 'enum.dart';
import 'log.dart';
import 'qpt.dart';
import 'utils.dart';

const String _TAG = 'PriorityPendingList';

abstract class PriorityPendingItem<ENUM extends EnumInt> {
  ENUM        priority;
  int         createUtc = utc();
  int         timeout;
  Error       error;
  bool        completed = false;

  List<Completer<void>> waiting = [];

  Future<void> start();

  void onComplete(error) {
    if (completed)
      Log.e(_TAG, "$runtimeType already completed: $this.", RuntimeException("never complete twice.").thrown());

    completed = true;
    error = error;
    waiting.forEach((w) => error == null ? w.complete(null) : w.completeError(error));
    waiting.clear();
  }

  Future<bool> waitComplete() {
    var c = Completer<bool>();

    if (completed) {
      error != null
          ? c.completeError(error)
          : c.complete(null);
    } else
      waiting.add(c);

    return c.future;
  }

  bool expired() {
    return utc() - createUtc >= timeout;
  }

  int get duration => utc() - createUtc;

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

  bool Function(ENUM priority)    priorityAllowed;

  int _size;
  int get size => _size ?? (_size = pending.isEmpty ? 0 : pending.values.fold(0, ((val, item) => val + item.length)));


  @protected
  List<ITEM> getList(ENUM priority) {
    return pending[priority] ?? (pending[priority] = []);
  }

  bool remove(ITEM item, { Error error, bool callOnRemove = true, }) {
    _size = null;

    bool r = pending[item.priority]?.remove(item);

    if (callOnRemove == true)
      _onRemoved(item, error);
    Timer.run(() => item.onComplete(error));

    return r;
  }

  void _onRemoved(ITEM item, Error e) {
    try {
      onRemoved(item, e);
    } catch (e) {
      Log.e(_TAG, "onRemove occurs error: ", e);
    }
  }

  void onRemoved(ITEM item, Error e) {
    return;
  }

  /// used to remove conflicted items.
  void removeConflict(ITEM item) {
    return;
  }

  Future<T> push<T extends ITEM>(ITEM item) async {
    var l = getList(item.priority);

    removeConflict(item);

    var maxPrSize = maxPrioritySize[item.priority];
    if (maxPrSize != null) {
      // remove the oldest.
      while (maxPrSize <= l.length) {
        var removed = l.removeAt(0);
        if (removed == null)
          continue;

        // Log.w(_TAG, 'removed too many item: $removed.');
        var e = PendingListFullError('priority list full.').thrown();
        _onRemoved(removed, e);
        Timer.run(() => removed.onComplete(e));
      }
    }

    _size = null;
    l.add(item);
    if (enableQpt) qpt.add();

    Log.d(_TAG, "push item: $item.");

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

      var l = pending[priority];
      if (l.length == 0)
        continue;

      var sz = min(l.length, removedSize);
      removedSize -= sz;

      removed.addAll(l.sublist(0, sz));
      l.removeRange(0, sz);
    }

    var e = PendingListFullError('max list full.').thrown();
    removed.forEach((r) {
      _onRemoved(r, e);
      Timer.run(() => r.onComplete(e));
    });

    Log.w(_TAG, 'removing low priority list: $removed.');
  }

  ITEM getNext({ bool remove = false, bool retry = false, }) {
    ITEM t;

    for (var priority in pending.keys) {
      var l = pending[priority];

      if (priorityAllowed != null && !priorityAllowed(priority)) {
        if (!retry) Log.w(_TAG, "Priority not allowed: $priority.");
        continue;
      }

      if (l.isEmpty) {
        continue;
      }

      t = l.removeAt(0);
      _onRemoved(t, null);
      break;
    }

    if (t != null)
      _size = null;

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
      Log.e(_TAG, 'startLoop fail, retry in 2s, error: ', e);

      delay(2000).then((_) => start());
    }
  }

  Future<void> _startLoop() async {
    var sUtc = startUtc;
    bool retry = false;
    while (true) {
      if (size == 0) {
        return;
      }

      if (startUtc != sUtc)
        return;

      retry = await next(retry: retry);
    }
  }

  /// returns retry.
  @protected
  Future<bool> next({ bool retry = false }) async {
    var item = getNext(retry: retry);

    if (item == null) {
      if (!retry) Log.w(_TAG, 'get item skipped, wait for next retry.');

      await delay(50);
      return true;
    }

    Log.d(_TAG, "start item: $item");

    processing.add(item);

    var error;
    try {
      // already timeout...
      if (item.expired()) {
        throw TimeoutException('item already expired.');
      }

      await item.start();
      Log.d(_TAG, "item result success, item: $item");
    } catch (e) {
      Log.e(_TAG, "item result failed, item: $item, error: ", e);
      error = e;
    }

    processing.remove(item);

    Timer.run(() => item.onComplete(error));

    return false;
  }

  @override
  String toString() {
    return "$runtimeType { qpt: $qpt, processing: ${processing.length}, pending: ${pending.keys.map((k) => "$k: ${pending[k].length}")}, }";
  }

}